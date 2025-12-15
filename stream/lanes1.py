import cv2
import numpy as np
import json
import requests
from requests.exceptions import Timeout, RequestException

STREAM_URL = "http://10.10.59.253:81/stream"
ROI_FILE = "lanes_roi.json"


# =========================================================
#  HÀM ĐỌC 1 FRAME TỪ MJPEG STREAM (CẢI TIẾN)
# =========================================================
def get_frame(url, timeout=5):
    """
    Đọc 1 frame từ MJPEG stream với timeout
    """
    try:
        r = requests.get(url, stream=True, timeout=timeout)
        bytes_data = b""
        max_bytes = 10 * 1024 * 1024  # Giới hạn 10MB để tránh memory leak

        for chunk in r.iter_content(chunk_size=4096):
            if not chunk:
                continue

            bytes_data += chunk

            # Tránh buffer quá lớn
            if len(bytes_data) > max_bytes:
                print(" Buffer quá lớn, reset...")
                bytes_data = bytes_data[-100000:]  # Giữ lại 100KB cuối

            # Tìm JPEG start và end markers
            a = bytes_data.find(b'\xff\xd8')  # JPEG start (SOI)
            b = bytes_data.find(b'\xff\xd9')  # JPEG end (EOI)

            if a != -1 and b != -1 and b > a:
                jpg = bytes_data[a:b + 2]
                bytes_data = bytes_data[b + 2:]

                # Decode JPEG
                frame = cv2.imdecode(np.frombuffer(jpg, dtype=np.uint8), cv2.IMREAD_COLOR)

                if frame is not None:
                    r.close()
                    return frame
                else:
                    print(" Decode JPEG failed, trying next frame...")

        r.close()
        return None

    except Timeout:
        print(f" Timeout khi kết nối tới {url}")
        return None
    except RequestException as e:
        print(f" Lỗi request: {e}")
        return None
    except Exception as e:
        print(f" Lỗi không xác định: {e}")
        return None


# =========================================================
#  HÀM CHỌN ROI BẰNG CHUỘT
# =========================================================
def select_polygon(frame, lane_name, color):
    points = []
    temp = frame.copy()
    display = frame.copy()

    print(f"\n===== {lane_name} =====")
    print("Click chuột trái để chọn điểm")
    print("ENTER: hoàn thành,  ESC: hủy")

    def mouse(event, x, y, flags, param):
        nonlocal points, display
        if event == cv2.EVENT_LBUTTONDOWN:
            points.append((x, y))
            cv2.circle(display, (x, y), 5, color, -1)

            if len(points) > 1:
                cv2.line(display, points[-2], points[-1], color, 2)

            cv2.imshow("Select ROI", display)

    cv2.imshow("Select ROI", display)
    cv2.setMouseCallback("Select ROI", mouse)

    while True:
        key = cv2.waitKey(1) & 0xFF
        if key == 13:  # ENTER
            if len(points) < 3:
                print(" Cần ít nhất 3 điểm!")
                continue
            cv2.destroyWindow("Select ROI")
            return np.array(points, dtype=np.int32)

        elif key == 27:  # ESC
            cv2.destroyWindow("Select ROI")
            return None


# =========================================================
#  MAIN LOGIC
# =========================================================
print(" Đang lấy frame đầu tiên từ ESP32-CAM...")
print(f" Đang kết nối tới: {STREAM_URL}")

# Thử kết nối với timeout
frame = None
max_retries = 3

for i in range(max_retries):
    print(f"Lần thử {i + 1}/{max_retries}...")
    frame = get_frame(STREAM_URL, timeout=10)

    if frame is not None:
        print(f" Đã lấy frame thành công! Kích thước: {frame.shape}")
        break
    else:
        print(f" Lần thử {i + 1} thất bại")
        if i < max_retries - 1:
            print("Đang thử lại sau 2 giây...")
            import time

            time.sleep(2)

if frame is None:
    print("\n KHÔNG THỂ LẤY FRAME!")
    print("\n Các bước kiểm tra:")
    print("1. Kiểm tra ESP32-CAM đã bật và kết nối WiFi chưa")
    print("2. Thử mở trên trình duyệt: http://192.168.100.114:81/stream")
    print("3. Kiểm tra IP có đúng không (xem Serial Monitor của ESP32)")
    print("4. Đảm bảo máy tính và ESP32 cùng mạng WiFi")
    exit()

cv2.imshow("Frame", frame)
cv2.waitKey(1)

# ============================
# LOAD ROIs NẾU TỒN TẠI
# ============================
lanes = []
colors = [(0, 255, 0), (0, 0, 255), (255, 0, 0), (0, 255, 255)]
lane_names = ["Lane 1", "Lane 2", "Lane 3", "Lane 4"]

try:
    with open(ROI_FILE, "r") as f:
        data = json.load(f)
        for lane in data:
            lanes.append(np.array(lane["points"], dtype=np.int32))

    print("\n Đã load ROI từ file → bỏ qua bước vẽ")
except:
    print("\n Không có file ROI → bắt đầu vẽ")

    for i in range(4):
        roi = select_polygon(frame, lane_names[i], colors[i])
        if roi is None:
            print("Hủy thao tác.")
            exit()
        lanes.append(roi)

    # LƯU LẠI
    save_data = []
    for i, l in enumerate(lanes):
        save_data.append({
            "name": lane_names[i],
            "points": l.tolist()
        })

    with open(ROI_FILE, "w") as f:
        json.dump(save_data, f, indent=4)
    print("✓ Đã lưu ROI vào lanes_roi.json")

# =========================================================
#  VẼ ROI LÊN FRAME
# =========================================================
print("\n Đang vẽ tất cả ROI lên frame...")
overlay = frame.copy()

for poly, color in zip(lanes, colors):
    cv2.polylines(overlay, [poly], True, color, 2)
    cv2.fillPoly(overlay, [poly], color=(color[0], color[1], color[2], 40))

alpha = 0.4
final = cv2.addWeighted(overlay, alpha, frame, 1 - alpha, 0)

cv2.imshow("Tất cả ROI", final)
cv2.waitKey(0)
cv2.destroyAllWindows()