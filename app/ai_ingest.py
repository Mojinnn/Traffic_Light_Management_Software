# app/ai_ingest.py
from fastapi import APIRouter, Depends, HTTPException, Header, BackgroundTasks
from sqlalchemy.orm import Session
from datetime import datetime
from . import schemas, models, database, notify, mqtt_client, auth
import os
import requests

from .auth import role_required
router = APIRouter(prefix="/api")

# ==========================
# Cấu hình
# ==========================
ALERT_THRESHOLD = int(os.environ.get("ALERT_THRESHOLD", 15))  # Ngưỡng cảnh báo
DEFAULT_LIGHT = {"red": 25, "yellow": 3, "green": 22}         # Thời gian đèn mặc định
#BACKEND_LIGHT_URL = "http://127.0.0.1:8000/api/lights"        # API để chỉnh đèn mặc định

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()
# ==========================
# POST – Ingest traffic count
# ==========================
@router.post("/traffic-count", status_code=201)
def ingest_traffic(
    data: schemas.TrafficCountIn,
    db: Session = Depends(get_db),
    user: models.User = Depends(role_required(["admin"])),
    background: BackgroundTasks = None
):
    # Lưu vào DB
    tc = models.TrafficCount(
        north=data.north,
        south=data.south,
        east=data.east,
        west=data.west
    )
    db.add(tc)
    db.commit()

    # ---------------- CHECK NGƯỠNG ----------------
    directions = {
        "north": data.north,
        "south": data.south,
        "east": data.east,
        "west": data.west,
    }

    exceeded = [d for d, v in directions.items() if v >= ALERT_THRESHOLD]

    # ===== Nếu có hướng vượt ngưỡng → gửi mail =====
    if exceeded:
        msg = "Hướng vượt ngưỡng: " + ", ".join(
            [f"{d} ({directions[d]})" for d in exceeded]
        )
        for d in exceeded:
            alert = models.AlertLog(
               camera_id=d,
               message=f"Hướng {d} vượt ngưỡng {ALERT_THRESHOLD}",
               value=directions[d]
            )
            db.add(alert)
        db.commit()

        recipients = [
            u.email for u in db.query(models.User)
            .filter(models.User.notify == True, models.User.role == "police")
        ]

        if recipients:
            background.add_task(
                notify.send_mail_sync,
                recipients,
                "[Traffic Alert] High Traffic Detected",
                msg
            )

    # ===== Nếu KHÔNG có hướng nào vượt ngưỡng → RESET LIGHT =====
    else:
        DEFAULT_LIGHT = {"red": 25, "yellow": 3, "green": 22}
        lights = db.query(models.LightSetting).all()
        for light in lights:
            light.red = DEFAULT_LIGHT["red"]
            light.yellow = DEFAULT_LIGHT["yellow"]
            light.green = DEFAULT_LIGHT["green"]
        db.commit()

    return {"ok": True}
# ==========================
# GET latest traffic count
# ==========================
@router.get("/traffic-count/latest", response_model=schemas.TrafficCountOut)
def get_latest(db: Session = Depends(get_db)):
    row = db.query(models.TrafficCount).order_by(models.TrafficCount.id.desc()).first()
    if not row:
        return {
            "timestamp": datetime.now(),
            "north": 0, "south": 0, "east": 0, "west": 0
        }
    return row


# ==========================
# GET history
# ==========================
@router.get("/traffic-count/history", response_model=list[schemas.TrafficCountOut])
def get_history(limit: int = 100, db: Session = Depends(get_db)):
    rows = (
        db.query(models.TrafficCount)
        .order_by(models.TrafficCount.timestamp.desc())
        .limit(limit)
        .all()
    )
    return rows[::-1]  # đảo lại từ cũ → mới


# ==========================
# DELETE history
# ==========================
@router.delete("/traffic-count", status_code=200)
def clear_all(
    db: Session = Depends(get_db),
    user: models.User = Depends(role_required(["admin"]))
):
    deleted = db.query(models.TrafficCount).delete()
    db.commit()
    return {"message": f"Deleted {deleted} rows."}


"""
@router.post("/Light Counter", status_code=201)
def ingest(
    data: schemas.IngestIn,
    db: Session = Depends(get_db),
    user: models.User = Depends(role_required(["admin"])),   # ⟵ CHỈ ADMIN
    background_tasks: BackgroundTasks = None
):
    # Save traffic
    td = models.TrafficData(
        camera_id=data.camera_id,
        count=data.count,
        meta=json.dumps(data.meta) if data.meta else None
    )
    db.add(td)
    db.commit()

    # If threshold exceeded → trigger alert
    if data.count >= ALERT_THRESHOLD:
        msg = (
            f"Alert: camera {data.camera_id} reported high traffic: "
            f"{data.count} (threshold {ALERT_THRESHOLD})"
        )

        # Save alert log
        al = models.AlertLog(
            camera_id=data.camera_id,
            message=msg,
            value=data.count
        )
        db.add(al)
        db.commit()

        # Get emails of users who want notifications
        recipients = [
            u.email for u in db.query(models.User)
            .filter(models.User.notify == True, models.User.role == "police")
            .all()
        ]

        if recipients:
            background_tasks.add_task(
                notify.send_mail_sync,
                recipients,
                f"[Traffic Alert] {data.camera_id}",
                msg
            )

    return {"ok": True}
@router.get("/Light Counter", response_model=list[schemas.TrafficOut])
def get_ingest(limit: int = 20, db: Session = Depends(get_db)):
    rows = db.query(models.TrafficData).order_by(models.TrafficData.timestamp.desc()).limit(limit).all()

    result = []
    for row in rows:

        meta = row.meta
        if isinstance(meta, str):
            try:
                meta = json.loads(meta)
            except:
                meta = None

        result.append({
            "id": row.id,
            "camera_id": row.camera_id,
            "count": row.count,
            "meta": meta,
            "timestamp": row.timestamp
        })
    return result


@router.delete("/Light Counter")
def clear_ingest(
    db: Session = Depends(get_db),
    user: models.User = Depends(role_required(["admin"]))  # ← CHỈ ADMIN
):
    deleted_count = db.query(models.TrafficData).delete()
    db.commit()
    return {"message": f"Deleted {deleted_count} rows."}
"""