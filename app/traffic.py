# app/traffic.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Literal, Optional, List
from datetime import datetime
import time
from threading import Thread, Lock
import json
import os

from .database import SessionLocal
from . import models

router = APIRouter(prefix="/traffic-lights", tags=["Traffic Lights"])

# ============================================
# CONSTANTS / DEFAULTS
# ============================================

CONFIG_FILE = "traffic_config.json"
YELLOW_DURATION = 3

# AUTO fixed: xanh 27s, vàng 3s
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
# API MODELS
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
    timerConfig: Optional[TimerConfig] = None  # AUTO/EMERGENCY không bắt buộc

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

# ============================================
# GLOBAL STATE (RAM)
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
# DB: SAVE FIXED SNAPSHOT (ONLY ON APPLY/LOAD)
# ============================================

def _save_to_traffic_lights_4ways(snapshot: Dict) -> None:
    """
    Lưu snapshot cố định vào bảng traffic_lights:
    - intersection_id: north/south/east/west
    - red/yellow/green theo timerConfig
    - EMERGENCY -> 0/0/0
    Chỉ gọi khi APPLY hoặc khi load_config startup.
    """
    db = SessionLocal()
    try:
        mode = snapshot.get("mode", "AUTO")
        cfg = snapshot.get("timerConfig", AUTO_FIXED_TIMER)

        mapping = {
            "North": "north",
            "South": "south",
            "East": "east",
            "West": "west",
        }

        now = datetime.utcnow()

        for k, db_dir in mapping.items():
            row = db.query(models.TrafficLight).filter_by(intersection_id=db_dir).first()
            if not row:
                row = models.TrafficLight(intersection_id=db_dir)
                db.add(row)

            if mode == "EMERGENCY":
                row.red = 0
                row.yellow = 0
                row.green = 0
            else:
                row.red = int(cfg[k]["red"])
                row.yellow = YELLOW_DURATION
                row.green = int(cfg[k]["green"])

            row.updated_at = now

        db.commit()
        print(f"✅ Saved 4-way snapshot to traffic_lights (mode={mode})")
    except Exception as e:
        print(f"❌ DB save traffic_lights error: {e}")
    finally:
        db.close()

# ============================================
# FILE SAVE/LOAD (NO DEADLOCK)
# ============================================

def _normalize_timer_config_dict(cfg: Dict) -> Dict[str, Dict[str, int]]:
    out: Dict[str, Dict[str, int]] = {}
    for d in ["North", "South", "East", "West"]:
        phases = cfg.get(d, {}) if isinstance(cfg, dict) else {}
        red = int(phases.get("red", 30))
        green = int(phases.get("green", 27))
        red = max(1, min(300, red))
        green = max(1, min(300, green))
        out[d] = {"red": red, "green": green}
    return out

def _snapshot_for_save_locked() -> Dict:
    """Must be called WITH lock held."""
    return {
        "mode": traffic_state["mode"],
        "timerConfig": traffic_state["timerConfig"],
    }

def _save_config_snapshot_to_file(snapshot: Dict) -> None:
    """Save config to file WITHOUT acquiring state_lock."""
    try:
        with open(CONFIG_FILE, "w") as f:
            json.dump(snapshot, f, indent=2)
        print("✅ Traffic config saved to file")
    except Exception as e:
        print(f"❌ Error saving traffic config: {e}")

def load_config():
    """Load persisted config file and apply to runtime state safely."""
    if not os.path.exists(CONFIG_FILE):
        # Không có file -> dùng AUTO mặc định + sync DB 1 lần để có 4 hướng
        snap = {"mode": "AUTO", "timerConfig": AUTO_FIXED_TIMER.copy()}
        _save_to_traffic_lights_4ways(snap)
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

            snap = _snapshot_for_save_locked()

        print("✅ Traffic config loaded from file")

        # ✅ sync DB 1 lần khi startup
        _save_to_traffic_lights_4ways(snap)

    except Exception as e:
        print(f"❌ Error loading traffic config: {e}")

# ============================================
# CYCLE / PHASE LOGIC (LOCKED)
# ============================================

def get_phase_duration_locked(phase: int) -> int:
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
    """Reset cycle timing + apply current phase to lights."""
    now = time.time()
    traffic_state["currentPhase"] = phase
    traffic_state["phaseStartTime"] = now
    traffic_state["cycleStartTime"] = now

    dur = get_phase_duration_locked(phase)
    _apply_phase_to_lights_locked(phase=phase, remaining=dur)

def _apply_phase_to_lights_locked(phase: int, remaining: int):
    # indices: 0=N,1=S,2=E,3=W
    if phase == 1:
        # E/W GREEN, N/S RED
        traffic_state["lights"][0]["state"] = "red"
        traffic_state["lights"][1]["state"] = "red"
        traffic_state["lights"][2]["state"] = "green"
        traffic_state["lights"][3]["state"] = "green"

        ns_red = remaining + YELLOW_DURATION
        traffic_state["lights"][0]["remainingTime"] = ns_red
        traffic_state["lights"][1]["remainingTime"] = ns_red
        traffic_state["lights"][2]["remainingTime"] = remaining
        traffic_state["lights"][3]["remainingTime"] = remaining

    elif phase == 2:
        # E/W YELLOW, N/S RED
        traffic_state["lights"][0]["state"] = "red"
        traffic_state["lights"][1]["state"] = "red"
        traffic_state["lights"][2]["state"] = "yellow"
        traffic_state["lights"][3]["state"] = "yellow"

        traffic_state["lights"][0]["remainingTime"] = remaining
        traffic_state["lights"][1]["remainingTime"] = remaining
        traffic_state["lights"][2]["remainingTime"] = remaining
        traffic_state["lights"][3]["remainingTime"] = remaining

    elif phase == 3:
        # N/S GREEN, E/W RED
        traffic_state["lights"][0]["state"] = "green"
        traffic_state["lights"][1]["state"] = "green"
        traffic_state["lights"][2]["state"] = "red"
        traffic_state["lights"][3]["state"] = "red"

        traffic_state["lights"][0]["remainingTime"] = remaining
        traffic_state["lights"][1]["remainingTime"] = remaining

        ew_red = remaining + YELLOW_DURATION
        traffic_state["lights"][2]["remainingTime"] = ew_red
        traffic_state["lights"][3]["remainingTime"] = ew_red

    elif phase == 4:
        # N/S YELLOW, E/W RED
        traffic_state["lights"][0]["state"] = "yellow"
        traffic_state["lights"][1]["state"] = "yellow"
        traffic_state["lights"][2]["state"] = "red"
        traffic_state["lights"][3]["state"] = "red"

        traffic_state["lights"][0]["remainingTime"] = remaining
        traffic_state["lights"][1]["remainingTime"] = remaining
        traffic_state["lights"][2]["remainingTime"] = remaining
        traffic_state["lights"][3]["remainingTime"] = remaining

def _update_cycle_locked():
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

# ============================================
# BACKGROUND THREAD (NO DB WRITES HERE)
# ============================================

def update_traffic_lights():
    """Background update thread. (NO DB writes here)"""
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
    """Realtime status (RAM)."""
    with state_lock:
        return {
            "mode": traffic_state["mode"],
            "timerConfig": traffic_state["timerConfig"],
            "lights": traffic_state["lights"],
        }

@router.get("/config", response_model=ConfigResponse)
async def get_config():
    """Current config (RAM)."""
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
    DB: chỉ lưu snapshot cố định 4 hướng khi APPLY.
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

            snapshot = _snapshot_for_save_locked()

        # ✅ save outside lock (avoid deadlock)
        if snapshot is not None:
            _save_config_snapshot_to_file(snapshot)

            # ✅ save fixed snapshot to DB (ONLY ON APPLY)
            _save_to_traffic_lights_4ways(snapshot)

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
