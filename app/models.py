# app/models.py
from sqlalchemy import Column, Integer, String, DateTime, Boolean, func, Text
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    firstname = Column(String)      # <-- thêm
    lastname = Column(String)       # <-- thêm
    role = Column(String, default="viewer")  # "admin" or "viewer"
    notify = Column(Boolean, default=True)   # whether this user wants email alerts
   
class TokenBlocklist(Base):
    __tablename__ = "token_blocklist"
    id = Column(Integer, primary_key=True, index=True)
    jti = Column(String, unique=True, index=True)
    revoked_at = Column(DateTime(timezone=True), server_default=func.now())

#class TrafficData(Base):
#    __tablename__ = "traffic_data"
#    id = Column(Integer, primary_key=True, index=True)
#    camera_id = Column(String, index=True)
#    count = Column(Integer)
#    meta = Column(Text, nullable=True)  # optional JSON metadata
#    timestamp = Column(DateTime(timezone=True), server_default=func.now())
class TrafficCount(Base):
    __tablename__ = "traffic_count"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    north = Column(Integer, default=0)
    south = Column(Integer, default=0)
    east = Column(Integer, default=0)
    west = Column(Integer, default=0)

class LightSetting(Base):
    __tablename__ = "light_settings"
    id = Column(Integer, primary_key=True, index=True)
    intersection = Column(String, unique=True, index=True)
    red = Column(Integer, default=30)
    yellow = Column(Integer, default=3)
    green = Column(Integer, default=27)
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

    id = Column(Integer, primary_key=True)
    email = Column(String, index=True)
    firstname = Column(String)
    lastname = Column(String)
    password = Column(String)
    code = Column(String)
    expires_at = Column(DateTime)


class ResetToken(Base):
    __tablename__ = "reset_tokens"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, index=True)
    token = Column(String, unique=True)
    expires_at = Column(DateTime)

class Feature(Base):
    __tablename__ = "features"

    id = Column(Integer, primary_key=True, index=True)
    feature_id = Column(String, unique=True, index=True)
    is_enabled = Column(Boolean, default=True)
