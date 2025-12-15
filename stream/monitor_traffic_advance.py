#!/usr/bin/env python3
# detect_stream_mjpeg_yolo_with_api.py
# MJPEG reader (requests) + YOLO detection + ROI counting + JSON export + Flask API
# Yêu cầu: opencv-python, requests, shapely, ultralytics, flask, flask-cors

import cv2
import numpy as np
import json
import time
from datetime import datetime, timezone
import requests
from shapely.geometry import Point, Polygon
from ultralytics import YOLO
import os
import sys
import traceback

# ---------- Thêm imports cho API ----------
from flask import Flask, Response, jsonify
from flask_cors import CORS
import threading
from threading import Lock

# =========================
# CONFIG
# =========================
ESP_STREAM_URL = "http://10.10.59.253:81/stream"
MODEL_PATH = "bestversion3.pt"
ROI_FILE = "lanes_roi.json"

# detection / performance
CONFIDENCE_THRESHOLD = 0.4
IOU_THRESHOLD = 0.5
PROCESS_EVERY_N_FRAMES = 1  # xử lý từng frame; tăng để giảm tải CPU
EXPORT_JSON_EVERY = 100  # xuất 1 file json mỗi N frame (có thể đặt 0 để tắt)

# output
SAVE_OUTPUT_VIDEO = False
OUTPUT_VIDEO_PATH = "traffic_density_esp32.avi"
JSON_OUTPUT_PATH = "traffic_export.json"  # sẽ ghi đè / append theo cấu trúc dưới

# reconnect
MAX_RECONNECT_ATTEMPTS = 5
STREAM_REQUEST_TIMEOUT = (5, 10)  # (connect timeout, read timeout)

# UI
WINDOW_NAME = "ESP32-CAM Traffic Analysis"

# ---------- Globals shared with API ----------
latest_frame = None  # BGR uint8 image (processed frame)
latest_lane_count = []  # list of ints
latest_timestamp = None  # ISO timestamp
latest_total_vehicles = 0  # tổng số xe
latest_proportions = []  # tỷ lệ % mỗi lane
shared_lock = Lock()

# =========================
# LOAD MODEL
# =========================
print("=" * 70)
print("          ESP32-CAM TRAFFIC DENSITY ANALYZER (MJPEG + YOLO)")
print("=" * 70)

try:
    print(" Loading YOLO model...")
    model = YOLO(MODEL_PATH)
    print(f" Model loaded: {MODEL_PATH}")
except Exception as e:
    print(f"Failed to load model: {e}")
    sys.exit(1)

# =========================
# LOAD ROI
# =========================
polygons = []
lane_names = []
vertices_list = []

try:
    with open(ROI_FILE, "r") as f:
        data = json.load(f)
        for lane in data:
            pts = np.array(lane["points"], dtype=np.int32)
            vertices_list.append(pts)
            polygons.append(Polygon(pts))
            lane_names.append(lane.get("name", f"Lane{len(polygons)}"))
    print(f" Loaded {len(polygons)} ROI zones from {ROI_FILE}")
except Exception as e:
    print(f"Cannot load ROI file '{ROI_FILE}': {e}")
    sys.exit(1)

num_lanes = len(polygons)
if num_lanes == 0:
    print(" No lanes found in ROI file.")
    sys.exit(1)

# Initialize latest_lane_count and latest_proportions
latest_lane_count = [0] * num_lanes
latest_proportions = [0.0] * num_lanes

# =========================
# UI / Colors
# =========================
font = cv2.FONT_HERSHEY_SIMPLEX
font_scale = 0.55
font_color = (255, 255, 255)
text_positions = [(20, 40 + i * 60) for i in range(num_lanes)]
lane_colors = [
    (0, 255, 0), (255, 0, 0), (0, 128, 255),
    (128, 0, 255), (255, 255, 0), (255, 0, 255)
]


# =========================
# MJPEG stream reader (requests)
# =========================
def connect_mjpeg(url):
    headers = {
        "User-Agent": "python-requests/esp32-mjpeg-client"
    }
    r = requests.get(url, stream=True, timeout=STREAM_REQUEST_TIMEOUT, headers=headers)
    r.raise_for_status()
    return r


def mjpeg_frame_generator(url):
    resp = connect_mjpeg(url)
    bytes_buffer = b""
    for chunk in resp.iter_content(chunk_size=4096):
        if chunk is None:
            continue
        bytes_buffer += chunk
        a = bytes_buffer.find(b'\xff\xd8')
        b = bytes_buffer.find(b'\xff\xd9')
        if a != -1 and b != -1 and b > a:
            jpg = bytes_buffer[a:b + 2]
            bytes_buffer = bytes_buffer[b + 2:]
            frame = cv2.imdecode(np.frombuffer(jpg, dtype=np.uint8), cv2.IMREAD_COLOR)
            if frame is None:
                continue
            yield frame
    resp.close()
    raise RuntimeError("MJPEG stream ended")


# =========================
# JSON export helper
# =========================
def export_json_snapshot(frame_idx, counts, polygons_names, out_path):
    timestamp = datetime.now(timezone.utc).isoformat()
    total = int(sum(counts))
    proportions = [(int(c) / total * 100) if total > 0 else 0.0 for c in counts]
    payload = {
        "timestamp": timestamp,
        "frame_index": int(frame_idx),
        "total_vehicles": int(total),
        "lanes": [
            {"name": polygons_names[i], "count": int(counts[i]), "proportion_percent": round(proportions[i], 1)}
            for i in range(len(counts))
        ]
    }
    try:
        if os.path.exists(out_path):
            with open(out_path, "r") as f:
                existing = json.load(f)
                if not isinstance(existing, list):
                    existing = []
        else:
            existing = []
        existing.append(payload)
        with open(out_path, "w") as f:
            json.dump(existing, f, indent=2)
        print(f" JSON exported ({len(existing)}) -> {out_path}")
    except Exception as e:
        print(f" Failed to export JSON: {e}")


# =========================
# Flask API (MJPEG stream of processed frames + lanes JSON)
# =========================
app = Flask(__name__)
CORS(app)  # Enable CORS for cross-origin requests


def mjpeg_response_generator():
    """
    Yield MJPEG parts built from latest_frame.
    """
    global latest_frame, shared_lock
    while True:
        with shared_lock:
            frame = None if latest_frame is None else latest_frame.copy()
        if frame is not None:
            ok, jpeg = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 85])
            if ok:
                chunk = jpeg.tobytes()
                yield (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + chunk + b'\r\n')
        time.sleep(0.03)  # ~30fps max


@app.route("/detect")  # MJPEG stream of processed frames
def stream_detect():
    return Response(mjpeg_response_generator(), mimetype="multipart/x-mixed-replace; boundary=frame")


@app.route("/lanes")
def get_lane_json():
    """
    Trả về dữ liệu JSON của các lanes với thông tin cập nhật liên tục
    """
    global latest_lane_count, latest_timestamp, latest_total_vehicles, latest_proportions

    with shared_lock:
        counts = list(latest_lane_count)
        ts = latest_timestamp
        total = latest_total_vehicles
        props = list(latest_proportions)

    resp = jsonify({
        "timestamp": ts,
        "total_vehicles": int(total),
        "lanes": [
            {
                "name": lane_names[i],
                "count": int(counts[i]),
                "proportion_percent": round(props[i], 1),
                "status": "Heavy" if counts[i] > 10 else "Smooth"
            }
            for i in range(num_lanes)
        ]
    })

    # Thêm headers để đảm bảo không cache, luôn lấy dữ liệu mới
    resp.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    resp.headers["Pragma"] = "no-cache"
    resp.headers["Expires"] = "0"
    return resp


@app.route("/lanes/stream")
def stream_lanes_json():
    """
    Server-Sent Events (SSE) stream để push dữ liệu lanes liên tục
    Client có thể subscribe để nhận updates real-time
    """

    def generate():
        global latest_lane_count, latest_timestamp, latest_total_vehicles, latest_proportions
        last_update = None

        while True:
            with shared_lock:
                current_timestamp = latest_timestamp

                # Chỉ gửi khi có update mới
                if current_timestamp != last_update:
                    counts = list(latest_lane_count)
                    total = latest_total_vehicles
                    props = list(latest_proportions)
                    last_update = current_timestamp

                    data = {
                        "timestamp": current_timestamp,
                        "total_vehicles": int(total),
                        "lanes": [
                            {
                                "name": lane_names[i],
                                "count": int(counts[i]),
                                "proportion_percent": round(props[i], 1),
                                "status": "Heavy" if counts[i] > 10 else "Smooth"
                            }
                            for i in range(num_lanes)
                        ]
                    }

                    yield f"data: {json.dumps(data)}\n\n"

            time.sleep(0.5)  # Update mỗi 0.5 giây

    return Response(generate(), mimetype="text/event-stream")
def run_api():
    # disable reloader to avoid double threads when run from script
    print("Starting API server...")
    app.run(host="0.0.0.0", port=5000, threaded=True, use_reloader=False)


# start API thread
api_thread = threading.Thread(target=run_api, daemon=True)
api_thread.start()
print("  API server started at http://<PC-IP>:5000")
print("  - Video stream: http://<PC-IP>:5000/detect")
print("  - Lanes data: http://<PC-IP>:5000/lanes")
print("  - Lanes stream: http://<PC-IP>:5000/lanes/stream")

# =========================
# MAIN LOOP (processing + updating shared variables for API)
# =========================
print(f"\n Connecting to ESP32 stream: {ESP_STREAM_URL}")
generator = None
reconnect_count = 0

# video writer init placeholder
out = None
first_frame_shape = None

frame_idx = 0
fps_start = time.time()
fps_count = 0
current_fps = 0.0

paused = False

# Start window (optional)
cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)

try:
    while True:
        # Ensure generator connected
        if generator is None:
            try:
                generator = mjpeg_frame_generator(ESP_STREAM_URL)
                reconnect_count = 0
                print(" MJPEG generator created")
            except Exception as e:
                reconnect_count += 1
                print(f" Connect failed ({reconnect_count}/{MAX_RECONNECT_ATTEMPTS}): {e}")
                if reconnect_count >= MAX_RECONNECT_ATTEMPTS:
                    print(" Max reconnect attempts reached. Exiting.")
                    raise
                time.sleep(2)
                generator = None
                continue

        # get next frame
        try:
            frame = next(generator)
        except StopIteration:
            print(" Stream ended (StopIteration). Reconnecting...")
            generator = None
            time.sleep(1)
            continue
        except Exception as e:
            print(f"Stream read error: {e}. Reconnecting...")
            generator = None
            time.sleep(1)
            continue

        if frame is None:
            continue

        # initialize writer if needed
        if first_frame_shape is None:
            first_frame_shape = frame.shape[:2]  # h,w
            if SAVE_OUTPUT_VIDEO:
                h, w = first_frame_shape
                fourcc = cv2.VideoWriter_fourcc(*'XVID')
                out = cv2.VideoWriter(OUTPUT_VIDEO_PATH, fourcc, 10.0, (w, h))
                print(f"✓ Video output: {OUTPUT_VIDEO_PATH}")

        frame_idx += 1
        fps_count += 1

        # FPS calc
        if time.time() - fps_start >= 1.0:
            elapsed = time.time() - fps_start
            current_fps = fps_count / elapsed
            fps_count = 0
            fps_start = time.time()

        # pause handling
        if paused:
            display_frame = frame.copy()
            cv2.putText(display_frame, "PAUSED", (10, 30), font, 1.0, (0, 0, 255), 2)
            cv2.imshow(WINDOW_NAME, display_frame)
            key = cv2.waitKey(30) & 0xFF
            if key == ord('p'):
                paused = False
            elif key == ord('q'):
                break
            # still update latest_frame for API during pause
            with shared_lock:
                latest_frame = display_frame.copy()
                latest_timestamp = datetime.now(timezone.utc).isoformat()
            continue

        # reduce processing rate if desired
        if (frame_idx % PROCESS_EVERY_N_FRAMES) != 0:
            display_frame = frame.copy()
            # update latest_frame as raw frame
            with shared_lock:
                latest_frame = display_frame.copy()
                latest_timestamp = datetime.now(timezone.utc).isoformat()
        else:
            # Run YOLO
            try:
                results = model.predict(frame,
                                        imgsz=640,
                                        conf=CONFIDENCE_THRESHOLD,
                                        iou=IOU_THRESHOLD,
                                        verbose=False)
                processed_frame = results[0].plot(line_width=2)
                # get boxes
                if results[0].boxes is not None and len(results[0].boxes) > 0:
                    try:
                        bounding_boxes = results[0].boxes.data.tolist()
                    except:
                        # fallback if .data not listable
                        try:
                            arr = results[0].boxes.xyxy.cpu().numpy()
                            bounding_boxes = [list(a) for a in arr]
                        except:
                            bounding_boxes = []
                else:
                    bounding_boxes = []
            except Exception as e:
                print(f"YOLO inference error: {e}")
                traceback.print_exc()
                processed_frame = frame.copy()
                bounding_boxes = []

            # counting per lane
            counts = [0] * num_lanes
            for box in bounding_boxes:
                try:
                    if len(box) >= 6:
                        x1, y1, x2, y2, conf, cls = box[:6]
                    else:
                        x1, y1, x2, y2 = box[:4]
                        conf = 1.0
                    cx = (x1 + x2) / 2.0
                    cy = (y1 + y2) / 2.0
                    p = Point(float(cx), float(cy))
                    for i, poly in enumerate(polygons):
                        try:
                            if poly.contains(p):
                                counts[i] += 1
                                break
                        except Exception:
                            continue
                except Exception:
                    continue

            total_vehicles = sum(counts)
            proportions = [(cnt / total_vehicles * 100.0) if total_vehicles > 0 else 0.0 for cnt in counts]

            # draw ROIs + labels
            for i in range(num_lanes):
                color = lane_colors[i % len(lane_colors)]
                cv2.polylines(processed_frame, [vertices_list[i]], True, color, 2)
                try:
                    centroid = polygons[i].centroid
                    label_pos = (int(centroid.x) - 30, int(centroid.y))
                    cv2.putText(processed_frame, lane_names[i], label_pos, font, 0.7, color, 2, cv2.LINE_AA)
                except:
                    pass

            # draw lane info on top-left
            for i in range(num_lanes):
                x, y = text_positions[i]
                status = "Heavy" if counts[i] > 10 else "Smooth"
                bg_color = (0, 0, 255) if status == "Heavy" else (0, 200, 0)
                text = f"{lane_names[i]}: {counts[i]} | {status} | {proportions[i]:.1f}%"
                (text_w, text_h), _ = cv2.getTextSize(text, font, font_scale, 2)
                cv2.rectangle(processed_frame, (x - 5, y - text_h - 5), (x + text_w + 5, y + 5), bg_color, -1)
                cv2.putText(processed_frame, text, (x, y), font, font_scale, font_color, 2, cv2.LINE_AA)

            # global info
            info_y = text_positions[-1][1] + 60
            cv2.rectangle(processed_frame, (10, info_y - 25), (420, info_y + 10), (50, 50, 50), -1)
            cv2.putText(processed_frame, f"Total: {total_vehicles} vehicles", (20, info_y), font, font_scale,
                        (0, 255, 255), 2)
            fps_y = info_y + 30
            cv2.putText(processed_frame, f"FPS: {current_fps:.1f} | Frame: {frame_idx}", (20, fps_y), font, 0.5,
                        (255, 255, 255), 1)

            display_frame = processed_frame

            # export JSON periodically
            if EXPORT_JSON_EVERY > 0 and (frame_idx % EXPORT_JSON_EVERY == 0):
                try:
                    export_json_snapshot(frame_idx, counts, lane_names, JSON_OUTPUT_PATH)
                except Exception as e:
                    print(f"JSON export failed: {e}")

            # CẬP NHẬT biến dùng cho API (thread-safe)
            with shared_lock:
                latest_frame = display_frame.copy()
                latest_lane_count = counts.copy()
                latest_total_vehicles = total_vehicles
                latest_proportions = proportions.copy()
                latest_timestamp = datetime.now(timezone.utc).isoformat()

        # write video if needed
        if SAVE_OUTPUT_VIDEO and display_frame is not None:
            out.write(display_frame)

        # show
        cv2.imshow(WINDOW_NAME, display_frame)
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            print("Quitting...")
            break
        elif key == ord('s'):
            fname = f"traffic_screenshot_{frame_idx}.jpg"
            cv2.imwrite(fname, display_frame)
            print(f"📸 Saved {fname}")
        elif key == ord('p'):
            paused = not paused
            print("Paused" if paused else "Resumed")

except KeyboardInterrupt:
    print("\n Interrupted by user")

except Exception as e:
    print("\nFatal error:")
    traceback.print_exc()

finally:
    print("\nCleaning up...")
    try:
        if out:
            out.release()
    except:
        pass
    cv2.destroyAllWindows()
    print(" Done")