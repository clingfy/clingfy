import 'dart:ui';

import 'package:clingfy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AppErrorWidgetBuilder {
  static Widget build(FlutterErrorDetails details) {
    final locale = PlatformDispatcher.instance.locale;
    final l10n = lookupAppLocalizations(locale);
    final textDirection = locale.languageCode.toLowerCase() == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: ColoredBox(
        color: Color(0xFF202020),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              l10n.renderingErrorFallbackMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
