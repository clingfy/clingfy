import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/ui/theme/app_shell_tokens.dart';
import 'package:flutter/material.dart';

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  AppLocalizations _l10n(BuildContext context) =>
      AppLocalizations.of(context) ??
      lookupAppLocalizations(
        Localizations.maybeLocaleOf(context) ??
            WidgetsBinding.instance.platformDispatcher.locale,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    final gradient = context.appTokens.shellGradient;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator.adaptive(),
                const SizedBox(height: 10),
                Text(l10n.loadingYourSettings),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
