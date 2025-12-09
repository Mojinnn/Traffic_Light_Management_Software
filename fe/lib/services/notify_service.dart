import 'dart:async';

import 'package:first_flutter/data/notifiers.dart';
import 'package:first_flutter/models/notify_model.dart';

class NotifyService {
  final StreamController<NotifyModel> _controller =
      StreamController<NotifyModel>.broadcast();

  Stream<NotifyModel> get stream => _controller.stream;

  // 👉 Gọi API thật / subscribe MQTT thật tại đây
  // Ở đây mình fake một notify mỗi 3 giây
  void startMockNotification() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      hasNewNotifyNotifier.value = true;
      _controller.add(
        NotifyModel(
          title: "New Alert",
          message: "Backend đã gửi một thông báo mới",
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void dispose() {
    _controller.close();
  }
}

// class NotifyService {
//   static Timer? _timer;
//   static bool _running = false;

//   static void startFakeBackend() {
//     if (_running) return;
//     _running = true;

//     _timer = Timer.periodic(Duration(seconds: 10), (timer) {
//       print("Fake backend: gửi notify mới");
//       hasNewNotifyNotifier.value = true;
//     });
//   }

//   static void stop() {
//     _timer?.cancel();
//     _running = false;
//   }
// }