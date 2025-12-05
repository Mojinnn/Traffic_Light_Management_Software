# app/models.py
from sqlalchemy import Column, Integer, String, DateTime, Boolean, func, Text
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="viewer")  # "admin" or "viewer"
    notify = Column(Boolean, default=True)   # whether this user wants email alerts
   
class TokenBlocklist(Base):
    __tablename__ = "token_blocklist"
    id = Column(Integer, primary_key=True, index=True)
    jti = Column(String, unique=True, index=True)
    revoked_at = Column(DateTime(timezone=True), server_default=func.now())

class TrafficData(Base):
    __tablename__ = "traffic_data"
    id = Column(Integer, primary_key=True, index=True)
    camera_id = Column(String, index=True)
    count = Column(Integer)
    meta = Column(Text, nullable=True)  # optional JSON metadata
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

class LightSetting(Base):
    __tablename__ = "light_settings"
    id = Column(Integer, primary_key=True, index=True)
    intersection = Column(String, unique=True, index=True)
    red = Column(Integer, default=10)
    yellow = Column(Integer, default=3)
    green = Column(Integer, default=12)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class AlertLog(Base):
    __tablename__ = "alert_logs"
    id = Column(Integer, primary_key=True, index=True)
    camera_id = Column(String)
    message = Column(String)
    value = Column(Integer)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
#-----------bo sung --------

class EmailVerify(Base):
    __tablename__ = "email_verify"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, index=True)
    code = Column(String)
    expires_at = Column(DateTime)

class ResetToken(Base):
    __tablename__ = "reset_tokens"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, index=True)
    token = Column(String, unique=True)
    expires_at = Column(DateTime)

