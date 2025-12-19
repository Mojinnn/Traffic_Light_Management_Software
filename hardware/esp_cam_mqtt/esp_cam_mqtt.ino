#include "esp_camera.h"
#include <WiFi.h>
#include "esp_http_server.h"

const char* ssid = "TTHocLieuT1";
const char* password = "hoclieut1";

// AI-Thinker Model Pin definition
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

httpd_handle_t stream_httpd = NULL;

// Thời gian khởi động server (để tính 10 giây)
unsigned long server_start_time = 0;

static esp_err_t stream_handler(httpd_req_t *req) {
  camera_fb_t * fb = NULL;
  esp_err_t res = ESP_OK;
  size_t _jpg_buf_len = 0;
  uint8_t * _jpg_buf = NULL;
  char part_buf[128];

  Serial.println(">>> Client connected!");

  // Set content type cho MJPEG stream
  res = httpd_resp_set_type(req, "multipart/x-mixed-replace; boundary=frame");
  if(res != ESP_OK){
    Serial.println(" Failed to set response type");
    return res;
  }

  // Lấy 1 frame để gửi (cho chế độ tĩnh)
  fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println(" Camera capture failed");
    return ESP_FAIL;
  }

  // Convert to JPEG nếu cần
  if(fb->format != PIXFORMAT_JPEG){
    bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
    esp_camera_fb_return(fb);
    fb = NULL;
    if(!jpeg_converted){
      Serial.println(" JPEG compression failed");
      return ESP_FAIL;
    }
  } else {
    _jpg_buf_len = fb->len;
    _jpg_buf = fb->buf;
  }

  int frame_count = 0;
  unsigned long static_mode_start = millis();

  // ===================================================================
  // CHẾ ĐỘ 1: GỬI FRAME TĨNH TRONG 10 GIÂY ĐẦU
  // ===================================================================
  Serial.println(" MODE: Static frame for 10 seconds");
  
  while(millis() - static_mode_start < 10000) {  // 10 giây
    // Gửi cùng 1 frame nhiều lần
    size_t hlen = snprintf(part_buf, sizeof(part_buf),
                           "--frame\r\n"
                           "Content-Type: image/jpeg\r\n"
                           "Content-Length: %u\r\n"
                           "\r\n", _jpg_buf_len);
    
    res = httpd_resp_send_chunk(req, part_buf, hlen);
    if(res != ESP_OK) break;

    res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
    if(res != ESP_OK) break;

    res = httpd_resp_send_chunk(req, "\r\n", 2);
    if(res != ESP_OK) break;

    frame_count++;
    
    // Log mỗi 2 giây
    if(frame_count % 20 == 0) {
      unsigned long remaining = 10 - ((millis() - static_mode_start) / 1000);
      Serial.printf("  Static mode: %lu seconds remaining\n", remaining);
    }

    // Delay giữa các frame tĩnh (khoảng 10 FPS)
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }

  Serial.println(" Static mode ended - Switching to video stream");

  // Cleanup frame tĩnh
  if(fb){
    esp_camera_fb_return(fb);
    fb = NULL;
    _jpg_buf = NULL;
  } else if(_jpg_buf){
    free(_jpg_buf);
    _jpg_buf = NULL;
  }

  // ===================================================================
  // CHẾ ĐỘ 2: STREAM VIDEO LIÊN TỤC
  // ===================================================================
  Serial.println(" MODE: Video streaming");

  frame_count = 0;

  while(true){
    fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println(" Camera capture failed");
      res = ESP_FAIL;
      break;
    }

    // Convert to JPEG nếu cần
    if(fb->format != PIXFORMAT_JPEG){
      bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
      esp_camera_fb_return(fb);
      fb = NULL;
      if(!jpeg_converted){
        Serial.println(" JPEG compression failed");
        res = ESP_FAIL;
        break;
      }
    } else {
      _jpg_buf_len = fb->len;
      _jpg_buf = fb->buf;
    }

    // Gửi frame
    size_t hlen = snprintf(part_buf, sizeof(part_buf),
                           "--frame\r\n"
                           "Content-Type: image/jpeg\r\n"
                           "Content-Length: %u\r\n"
                           "\r\n", _jpg_buf_len);
    
    res = httpd_resp_send_chunk(req, part_buf, hlen);
    if(res != ESP_OK){
      Serial.println(" Failed to send header");
      break;
    }

    res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
    if(res != ESP_OK){
      Serial.println(" Failed to send image");
      break;
    }

    res = httpd_resp_send_chunk(req, "\r\n", 2);
    if(res != ESP_OK){
      Serial.println("Failed to send tail");
      break;
    }

    // Cleanup
    if(fb){
      esp_camera_fb_return(fb);
      fb = NULL;
      _jpg_buf = NULL;
    } else if(_jpg_buf){
      free(_jpg_buf);
      _jpg_buf = NULL;
    }

    // Log mỗi 30 frames
    frame_count++;
    if(frame_count % 30 == 0){
      Serial.printf(" Video: %d frames streamed\n", frame_count);
    }

    // Delay nhỏ để stream mượt
    vTaskDelay(10 / portTICK_PERIOD_MS);
  }

  // Cleanup
  if(fb){
    esp_camera_fb_return(fb);
  }
  if(_jpg_buf){
    free(_jpg_buf);
  }

  Serial.printf(">>> Stream ended - Total video frames: %d\n", frame_count);
  return res;
}

void startCameraServer(){
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = 81;
  config.max_open_sockets = 7;
  config.lru_purge_enable = true;

  httpd_uri_t stream_uri = {
    .uri       = "/stream",
    .method    = HTTP_GET,
    .handler   = stream_handler,
    .user_ctx  = NULL
  };
  
  if (httpd_start(&stream_httpd, &config) == ESP_OK) {
    httpd_register_uri_handler(stream_httpd, &stream_uri);
    Serial.println(" Camera server started on port 81");
    server_start_time = millis();
  } else {
    Serial.println(" Failed to start server");
  }
}

void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(false);
  Serial.println();
  Serial.println("==========================================");
  Serial.println("    ESP32-CAM HYBRID STREAM MODE");
  Serial.println("  (10s Static → Then Video Stream)");
  Serial.println("==========================================");

  // Camera config
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_LATEST;

  // Cấu hình frame size
  if(psramFound()){
    config.frame_size = FRAMESIZE_VGA;
    config.jpeg_quality = 12;
    config.fb_count = 2;
    Serial.println(" PSRAM detected - VGA mode");
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
    Serial.println("No PSRAM - SVGA mode");
  }

  // Camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf(" Camera init failed: 0x%x\n", err);
    delay(3000);
    ESP.restart();
  }
  Serial.println(" Camera initialized");

  // Test camera
  camera_fb_t * test_fb = esp_camera_fb_get();
  if(test_fb) {
    Serial.printf(" Camera test OK - Image: %d bytes\n", test_fb->len);
    esp_camera_fb_return(test_fb);
  } else {
    Serial.println(" Camera test FAILED!");
  }

  // Sensor settings
  sensor_t * s = esp_camera_sensor_get();
  if(s) {
    s->set_brightness(s, 0);
    s->set_contrast(s, 0);
    s->set_saturation(s, 0);
    s->set_whitebal(s, 1);
    s->set_awb_gain(s, 1);
    s->set_wb_mode(s, 0);
    s->set_exposure_ctrl(s, 1);
    s->set_aec2(s, 0);
    s->set_gain_ctrl(s, 1);
    s->set_agc_gain(s, 0);
    s->set_gainceiling(s, (gainceiling_t)0);
    s->set_bpc(s, 0);
    s->set_wpc(s, 1);
    s->set_raw_gma(s, 1);
    s->set_lenc(s, 1);
    s->set_hmirror(s, 0);
    s->set_vflip(s, 0);
    s->set_dcw(s, 1);
    s->set_colorbar(s, 0);
  }

  // WiFi connection
  Serial.printf("Connecting to WiFi: %s ", ssid);
  WiFi.begin(ssid, password);
  WiFi.setSleep(false);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if(WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.println("WiFi connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.println();
    Serial.println("==========================================");
    Serial.print("  Stream URL: http://");
    Serial.print(WiFi.localIP());
    Serial.println(":81/stream");
    Serial.println("==========================================");
    Serial.println();
    Serial.println("ℹ️  First 10 seconds: Static frame");
    Serial.println("ℹ️  After 10 seconds: Video stream");
    Serial.println();

    startCameraServer();
  } else {
    Serial.println();
    Serial.println(" WiFi connection failed!");
    delay(3000);
    ESP.restart();
  }
}

void loop() {
  static unsigned long last_check = 0;
  if(millis() - last_check > 10000) {
    last_check = millis();
    if(WiFi.status() != WL_CONNECTED) {
      Serial.println(" WiFi lost - reconnecting...");
      WiFi.reconnect();
    }
  }
  delay(100);
}
