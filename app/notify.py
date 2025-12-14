
# # app/notify.py
# import os
# import smtplib
# from email.mime.text import MIMEText
# from typing import List
# from . import utils

# SMTP_HOST = os.environ.get("SMTP_HOST", "smtp.gmail.com")
# SMTP_PORT = int(os.environ.get("SMTP_PORT", 587))
# SMTP_USER = os.environ.get("SMTP_USER", "")   # set in env
# SMTP_PASS = os.environ.get("SMTP_PASS", "")   # set in env
# FROM = SMTP_USER

# def send_mail_sync(to_emails: List[str], subject: str, body: str):
#     if not SMTP_USER or not SMTP_PASS:
#         print("SMTP not configured; skipping send_mail")
#         return
#     msg = MIMEText(body)
#     msg["Subject"] = subject
#     msg["From"] = FROM
#     msg["To"] = ", ".join(to_emails if isinstance(to_emails, list) else [to_emails])
#     s = smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=10)
#     s.starttls()
#     s.login(SMTP_USER, SMTP_PASS)
#     s.sendmail(FROM, to_emails, msg.as_string())
#     s.quit()

# app/notify.py
import os
import smtplib
from email.mime.text import MIMEText
from typing import List

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.sendgrid.net")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASS = os.getenv("SMTP_PASS", "")
MAIL_FROM = os.getenv("MAIL_FROM", SMTP_USER)


def send_mail_sync(to_emails: List[str], subject: str, body: str):
    if not SMTP_USER or not SMTP_PASS:
        print("❌ SMTP not configured")
        return

    if isinstance(to_emails, str):
        to_emails = [to_emails]

    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = subject
    msg["From"] = MAIL_FROM
    msg["To"] = ", ".join(to_emails)

    try:
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15)
        server.ehlo()
        server.starttls()
        server.login(SMTP_USER, SMTP_PASS)
        server.sendmail(MAIL_FROM, to_emails, msg.as_string())
        server.quit()

        print(f"✅ Email sent to {to_emails}")

    except Exception as e:
        print("❌ Send mail failed:", e)
        raise
