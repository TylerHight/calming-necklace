part of 'timed_toggle_button_bloc.dart';

class PeriodicEmissionTicker {
  final int interval;
  Timer? _timer;
  final StreamController<int> _controller = StreamController<int>.broadcast();

  PeriodicEmissionTicker({required this.interval});

  Stream<int> tick() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: interval), (timer) {
      _controller.add(interval);
    });
    return _controller.stream;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
