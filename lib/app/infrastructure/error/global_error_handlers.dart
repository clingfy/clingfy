import 'dart:developer' as developer;
import 'dart:ui';

import 'package:clingfy/app/infrastructure/error/error_widget_builder.dart';
import 'package:flutter/material.dart';

class GlobalErrorHandlers {
  static void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      developer.log(
        'Flutter framework error',
        name: 'clingfy.flutter',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      developer.log(
        'Uncaught root isolate error',
        name: 'clingfy.platform',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    ErrorWidget.builder = AppErrorWidgetBuilder.build;
  }
}
