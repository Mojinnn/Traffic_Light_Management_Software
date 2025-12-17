# app/schemas.py
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    firstname: str = None   # có thể để optional
    lastname: str = None
from pydantic import BaseModel
class ChangePassword(BaseModel):
    old_password: str
    new_password: str
class UserOut(BaseModel):
    id: int
    email: EmailStr
    role: str
    notify: bool
    firstname: Optional[str] = None
    lastname: Optional[str] = None   # thêm
    class Config:
        orm_mode = True

class TokenResp(BaseModel):
    access_token: str
    token_type: str = "bearer"


#class IngestIn(BaseModel):
#    camera_id: str
#    count: int
#    meta: Optional[dict] = None
class TrafficCountIn(BaseModel):
    north: int
    south: int
    east: int
    west: int
#class TrafficOut(BaseModel):
#    id: int
#    camera_id: str
#    count: int
#    meta: Optional[dict]
#    timestamp: datetime
#    class Config:
#        orm_mode = True
class TrafficCountOut(BaseModel):
    timestamp: datetime
    north: int
    south: int
    east: int
    west: int

    class Config:
        orm_mode = True


# class LightSettingIn(BaseModel):
#     intersection: str
#     red: int
#     yellow: int
#     green: int

# class LightSettingOut(BaseModel):
#     id: int
#     intersection: str
#     red: int
#     yellow: int
#     green: int
#     updated_at: Optional[datetime]
#     class Config:
#         orm_mode = True

class AlertLogOut(BaseModel):
    id: int
    camera_id: Optional[str] = None
    message: str
    value: int
    timestamp: datetime
    class Config:
        orm_mode = True

#-bo sung



class ForgotPasswordIn(BaseModel):
    email: EmailStr
    
class ResetPasswordIn(BaseModel):
    token: str
    new_password: str

class ChangePasswordIn(BaseModel):
    old_password: str
    new_password: str
    retype_password: str


class RegisterSendCodeIn(BaseModel):
    email: EmailStr
    firstname: str
    lastname: str
    password: str
    retype_password: str


class RegisterConfirmIn(BaseModel):
    email: EmailStr
    code: str
class FeatureBase(BaseModel):
    featureId: str
    isEnabled: bool

class FeatureOut(FeatureBase):
    pass

class FeatureList(BaseModel):
    features: list[FeatureOut]
