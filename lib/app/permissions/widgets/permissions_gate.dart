import 'package:flutter/material.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/app/permissions/permissions_controller.dart';
import 'package:clingfy/app/permissions/screens/permissions_onboarding_screen.dart';

class PermissionsGate extends StatefulWidget {
  const PermissionsGate({
    super.key,
    required this.nativeBridge,
    required this.child,
  });

  final NativeBridge nativeBridge;
  final Widget child;

  @override
  State<PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends State<PermissionsGate>
    with WidgetsBindingObserver {
  late final PermissionsController _controller;

  bool _booted = false;
  bool _showOnboarding = false;
  int _initialStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PermissionsController(bridge: widget.nativeBridge);
    _boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refresh();
    }
  }

  Future<void> _boot() async {
    await _controller.refresh();
    final completed = await _controller.getOnboardingSeen();
    final step = await _controller.getOnboardingStep();

    final needs = !completed;

    if (!mounted) return;
    setState(() {
      _showOnboarding = needs;
      _initialStep = needs ? step : 0;
      _booted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_booted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showOnboarding) {
      return PermissionsOnboardingScreen(
        controller: _controller,
        initialStep: _initialStep,
        onFinished: () {
          setState(() {
            _showOnboarding = false;
            _initialStep = 0;
          });
        },
      );
    }

    return widget.child;
  }
}
