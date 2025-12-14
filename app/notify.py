
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
from typing import List
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY", "")
MAIL_FROM = os.getenv("MAIL_FROM", "")

def send_mail_sync(to_emails: List[str], subject: str, body: str):
    if not SENDGRID_API_KEY or not MAIL_FROM:
        print("❌ SENDGRID not configured")
        return

    if isinstance(to_emails, str):
        to_emails = [to_emails]

    message = Mail(
        from_email=MAIL_FROM,
        to_emails=to_emails,
        subject=subject,
        plain_text_content=body
    )

    try:
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        resp = sg.send(message)
        print("✅ SendGrid API sent:", resp.status_code)
    except Exception as e:
        print("❌ SendGrid API failed:", e)
        raise
