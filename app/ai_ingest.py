# app/ai_ingest.py
from fastapi import APIRouter, Depends, HTTPException, Header, BackgroundTasks
from sqlalchemy.orm import Session
from . import schemas, models, database, notify, mqtt_client, auth
import os
import json

from .auth import role_required
router = APIRouter(prefix="/api") 

# API key to protect AI uploader
# AI_KEY = os.environ.get("AI_INGEST_API_KEY", "dev_key_123")
ALERT_THRESHOLD = int(os.environ.get("ALERT_THRESHOLD", 15))  # threshold count to trigger email

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

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
