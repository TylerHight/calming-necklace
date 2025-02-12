import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/logging_service.dart';

class AppBlocObserver extends BlocObserver {
  late final LoggingService _logger;

  AppBlocObserver() {
    LoggingService.getInstance().then((logger) {
      _logger = logger;
    });
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.logDebug('Event: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.logDebug('Change: $change');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.logDebug('Transition: $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.logError('Error: $error', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
