# app/traffic.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Literal, Optional, List
from datetime import datetime
import time
from threading import Thread, Lock
import json
import os

router = APIRouter(prefix="/traffic-lights", tags=["Traffic Lights"])

# ============================================
# CONSTANTS / DEFAULTS
# ============================================

CONFIG_FILE = "traffic_config.json"
YELLOW_DURATION = 3

# AUTO fixed: xanh 27s, vàng 3s => hướng đối diện đỏ ~ 30s
AUTO_FIXED_TIMER: Dict[str, Dict[str, int]] = {
    "North": {"red": 30, "green": 27},
    "South": {"red": 30, "green": 27},
    "East":  {"red": 30, "green": 27},
    "West":  {"red": 30, "green": 27},
}

LIGHTS_DEFAULT = [
    {"id": 1, "name": "North", "state": "red",   "remainingTime": 30},
    {"id": 2, "name": "South", "state": "red",   "remainingTime": 30},
    {"id": 3, "name": "East",  "state": "green", "remainingTime": 27},
    {"id": 4, "name": "West",  "state": "green", "remainingTime": 27},
]

ModeLiteral = Literal["AUTO", "MANUAL", "EMERGENCY", "AI-BASED"]
LightStateLiteral = Literal["red", "yellow", "green"]

# ============================================
# DATA MODELS
# ============================================

class TimerPhase(BaseModel):
    red: int = Field(ge=1, le=300)
    green: int = Field(ge=1, le=300)

class TimerConfig(BaseModel):
    North: TimerPhase
    South: TimerPhase
    East: TimerPhase
    West: TimerPhase

class TrafficControlRequest(BaseModel):
    mode: ModeLiteral
    # AUTO/EMERGENCY không bắt buộc gửi timerConfig
    timerConfig: Optional[TimerConfig] = None

class LightStatus(BaseModel):
    id: int
    name: str
    state: LightStateLiteral
    remainingTime: int

class TrafficStatusResponse(BaseModel):
    mode: str
    timerConfig: Dict[str, Dict[str, int]]
    lights: List[LightStatus]

class ConfigResponse(BaseModel):
    mode: str
    timerConfig: Dict[str, Dict[str, int]]

# (Optional) nếu sau này bạn dùng
class ManualControlRequest(BaseModel):
    lightId: int
    state: LightStateLiteral

# ============================================
# GLOBAL STATE
# ============================================

traffic_state = {
    "mode": "AUTO",
    "timerConfig": AUTO_FIXED_TIMER.copy(),
    "lights": [l.copy() for l in LIGHTS_DEFAULT],
    # 1: E/W green, 2: E/W yellow, 3: N/S green, 4: N/S yellow
    "currentPhase": 1,
    "phaseStartTime": time.time(),
    "cycleStartTime": time.time(),
}

state_lock = Lock()
update_thread: Optional[Thread] = None

# ============================================
# HELPERS (NO DEADLOCK)
# ============================================

def _normalize_timer_config_dict(cfg: Dict) -> Dict[str, Dict[str, int]]:
    """Ensure full keys exist and clamp values."""
    out: Dict[str, Dict[str, int]] = {}
    for d in ["North", "South", "East", "West"]:
        phases = cfg.get(d, {}) if isinstance(cfg, dict) else {}
        red = int(phases.get("red", 30))
        green = int(phases.get("green", 27))
        red = max(1, min(300, red))
        green = max(1, min(300, green))
        out[d] = {"red": red, "green": green}
    return out

def _snapshot_for_save() -> Dict:
    """Return snapshot dict for saving to file. Must be called WITH lock held."""
    return {
        "mode": traffic_state["mode"],
        "timerConfig": traffic_state["timerConfig"],
    }

def _save_config_snapshot(snapshot: Dict) -> None:
    """Save snapshot to file WITHOUT acquiring state_lock (avoids deadlock)."""
    try:
        with open(CONFIG_FILE, "w") as f:
            json.dump(snapshot, f, indent=2)
        print("✅ Traffic config saved to file")
    except Exception as e:
        print(f"❌ Error saving traffic config: {e}")

def load_config():
    """Load persisted config file, then set state safely."""
    if not os.path.exists(CONFIG_FILE):
        return

    try:
        with open(CONFIG_FILE, "r") as f:
            data = json.load(f)

        mode = data.get("mode", "AUTO")
        timer_cfg = data.get("timerConfig", AUTO_FIXED_TIMER)

        with state_lock:
            if mode == "AUTO":
                traffic_state["mode"] = "AUTO"
                traffic_state["timerConfig"] = AUTO_FIXED_TIMER.copy()
                _reset_cycle_locked(phase=1)
            elif mode == "MANUAL":
                traffic_state["mode"] = "MANUAL"
                traffic_state["timerConfig"] = _normalize_timer_config_dict(timer_cfg)
                _reset_cycle_locked(phase=1)
            elif mode == "AI-BASED":
                traffic_state["mode"] = "AI-BASED"
                # placeholder: keep saved config or fixed; mình chọn fixed cho ổn định
                traffic_state["timerConfig"] = AUTO_FIXED_TIMER.copy()
                _reset_cycle_locked(phase=1)
            elif mode == "EMERGENCY":
                traffic_state["mode"] = "EMERGENCY"
                traffic_state["timerConfig"] = _normalize_timer_config_dict(timer_cfg)
                _set_emergency_locked()
            else:
                traffic_state["mode"] = "AUTO"
                traffic_state["timerConfig"] = AUTO_FIXED_TIMER.copy()
                _reset_cycle_locked(phase=1)

        print("✅ Traffic config loaded from file")
    except Exception as e:
        print(f"❌ Error loading traffic config: {e}")

def get_phase_duration_locked(phase: int) -> int:
    """Get duration for the given phase (requires state_lock held)."""
    cfg = traffic_state["timerConfig"]
    if phase == 1:
        return int(cfg["East"]["green"])      # E/W green
    if phase == 2:
        return YELLOW_DURATION               # E/W yellow
    if phase == 3:
        return int(cfg["North"]["green"])    # N/S green
    if phase == 4:
        return YELLOW_DURATION               # N/S yellow
    return 10

def _set_emergency_locked():
    """All red, stop countdown."""
    for light in traffic_state["lights"]:
        light["state"] = "red"
        light["remainingTime"] = 0

def _reset_cycle_locked(phase: int = 1):
    """Reset cycle timing + immediately apply phase to lights."""
    now = time.time()
    traffic_state["currentPhase"] = phase
    traffic_state["phaseStartTime"] = now
    traffic_state["cycleStartTime"] = now

    dur = get_phase_duration_locked(phase)
    _apply_phase_to_lights_locked(phase=phase, remaining=dur)

def _apply_phase_to_lights_locked(phase: int, remaining: int):
    """
    Update lights based on phase and remaining time (lock held).

    Convention:
    - remaining = time left for CURRENT phase only
    - For RED lights: remainingTime = time left until they turn GREEN (next green start)
    """

    # indices: 0=N,1=S,2=E,3=W
    if phase == 1:
        # Phase 1: East/West GREEN, North/South RED
        traffic_state["lights"][0]["state"] = "red"
        traffic_state["lights"][1]["state"] = "red"
        traffic_state["lights"][2]["state"] = "green"
        traffic_state["lights"][3]["state"] = "green"

        # N/S will turn GREEN at start of Phase 3:
        # time left = remaining(E/W green) + yellow(E/W)
        ns_red = remaining + YELLOW_DURATION
        traffic_state["lights"][0]["remainingTime"] = ns_red
        traffic_state["lights"][1]["remainingTime"] = ns_red

        traffic_state["lights"][2]["remainingTime"] = remaining
        traffic_state["lights"][3]["remainingTime"] = remaining

    elif phase == 2:
        # Phase 2: East/West YELLOW, North/South RED
        traffic_state["lights"][0]["state"] = "red"
        traffic_state["lights"][1]["state"] = "red"
        traffic_state["lights"][2]["state"] = "yellow"
        traffic_state["lights"][3]["state"] = "yellow"

        # During E/W yellow, N/S still red and will turn green when this yellow ends
        traffic_state["lights"][0]["remainingTime"] = remaining
        traffic_state["lights"][1]["remainingTime"] = remaining

        traffic_state["lights"][2]["remainingTime"] = remaining
        traffic_state["lights"][3]["remainingTime"] = remaining

    elif phase == 3:
        # Phase 3: North/South GREEN, East/West RED
        traffic_state["lights"][0]["state"] = "green"
        traffic_state["lights"][1]["state"] = "green"
        traffic_state["lights"][2]["state"] = "red"
        traffic_state["lights"][3]["state"] = "red"

        traffic_state["lights"][0]["remainingTime"] = remaining
        traffic_state["lights"][1]["remainingTime"] = remaining

        # E/W will turn GREEN at start of Phase 1:
        # time left = remaining(N/S green) + yellow(N/S)
        ew_red = remaining + YELLOW_DURATION
        traffic_state["lights"][2]["remainingTime"] = ew_red
        traffic_state["lights"][3]["remainingTime"] = ew_red

    elif phase == 4:
        # Phase 4: North/South YELLOW, East/West RED
        traffic_state["lights"][0]["state"] = "yellow"
        traffic_state["lights"][1]["state"] = "yellow"
        traffic_state["lights"][2]["state"] = "red"
        traffic_state["lights"][3]["state"] = "red"

        traffic_state["lights"][0]["remainingTime"] = remaining
        traffic_state["lights"][1]["remainingTime"] = remaining

        # During N/S yellow, E/W still red and will turn green when this yellow ends
        traffic_state["lights"][2]["remainingTime"] = remaining
        traffic_state["lights"][3]["remainingTime"] = remaining

def _update_cycle_locked():
    """Advance phase + update remaining time (lock held)."""
    now = time.time()
    phase = traffic_state["currentPhase"]
    phase_start = traffic_state["phaseStartTime"]
    duration = get_phase_duration_locked(phase)

    elapsed = now - phase_start
    if elapsed >= duration:
        phase = (phase % 4) + 1
        traffic_state["currentPhase"] = phase
        traffic_state["phaseStartTime"] = now
        if phase == 1:
            traffic_state["cycleStartTime"] = now

        duration = get_phase_duration_locked(phase)
        elapsed = 0

    remaining = max(0, int(duration - elapsed))
    _apply_phase_to_lights_locked(phase=phase, remaining=remaining)

def update_traffic_lights():
    """Background update thread."""
    while True:
        try:
            with state_lock:
                mode = traffic_state["mode"]

                if mode in ["AUTO", "MANUAL", "AI-BASED"]:
                    _update_cycle_locked()
                elif mode == "EMERGENCY":
                    _set_emergency_locked()
                else:
                    traffic_state["mode"] = "AUTO"
                    traffic_state["timerConfig"] = AUTO_FIXED_TIMER.copy()
                    _reset_cycle_locked(phase=1)

            time.sleep(1)
        except Exception as e:
            print(f"❌ Error in traffic light update: {e}")
            time.sleep(1)

def start_traffic_system():
    """Start background thread once."""
    global update_thread
    if update_thread is None or not update_thread.is_alive():
        load_config()
        update_thread = Thread(target=update_traffic_lights, daemon=True)
        update_thread.start()
        print("✅ Traffic light system started")

# ============================================
# API ENDPOINTS
# ============================================

@router.get("/status", response_model=TrafficStatusResponse)
async def get_status():
    with state_lock:
        return {
            "mode": traffic_state["mode"],
            "timerConfig": traffic_state["timerConfig"],
            "lights": traffic_state["lights"],
        }

@router.get("/config", response_model=ConfigResponse)
async def get_config():
    with state_lock:
        return {
            "mode": traffic_state["mode"],
            "timerConfig": traffic_state["timerConfig"],
        }

@router.post("/control")
async def control_lights(request: TrafficControlRequest):
    """
    Apply configuration:
    - AUTO: reset fixed timer (30/3/27 behavior)
    - MANUAL: apply timerConfig
    - EMERGENCY: all red
    - AI-BASED: placeholder = AUTO fixed
    """
    snapshot: Optional[Dict] = None

    try:
        with state_lock:
            traffic_state["mode"] = request.mode
            print(f"🔄 Traffic mode changed to: {request.mode}")

            if request.mode == "AUTO":
                traffic_state["timerConfig"] = AUTO_FIXED_TIMER.copy()
                _reset_cycle_locked(phase=1)

            elif request.mode == "MANUAL":
                if request.timerConfig is None:
                    raise HTTPException(status_code=400, detail="timerConfig is required for MANUAL mode")
                traffic_state["timerConfig"] = request.timerConfig.dict()
                _reset_cycle_locked(phase=1)

            elif request.mode == "AI-BASED":
                traffic_state["timerConfig"] = AUTO_FIXED_TIMER.copy()
                _reset_cycle_locked(phase=1)

            elif request.mode == "EMERGENCY":
                _set_emergency_locked()

            # snapshot inside lock
            snapshot = _snapshot_for_save()

        # ✅ save outside lock (no deadlock)
        if snapshot is not None:
            _save_config_snapshot(snapshot)

        return {"success": True, "message": "Configuration updated successfully"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "mode": traffic_state["mode"],
    }
#dacapnhap