from app.database import engine, Base
import app.models  # quan trọng: phải import models để Base biết bảng mới

print("Creating tables...")
Base.metadata.create_all(bind=engine)
print("Done.")
#------Chạy:-------
#python create_tables.py