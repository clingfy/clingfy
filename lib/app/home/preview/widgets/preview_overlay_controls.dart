import 'dart:async';
import 'package:flutter/material.dart';

class PreviewWithOverlayControls extends StatefulWidget {
  final Widget preview;
  final bool isPlaying;
  final bool controlsEnabled;
  final bool allowOverlayInteraction;
  final Function(bool) onPlayPause;

  const PreviewWithOverlayControls({
    super.key,
    required this.preview,
    required this.isPlaying,
    required this.controlsEnabled,
    bool? allowOverlayInteraction,
    required this.onPlayPause,
  }) : allowOverlayInteraction = allowOverlayInteraction ?? controlsEnabled;

  @override
  State<PreviewWithOverlayControls> createState() =>
      _PreviewWithOverlayControlsState();
}

class _PreviewWithOverlayControlsState
    extends State<PreviewWithOverlayControls> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.controlsEnabled) {
      _startHideTimer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    if (!widget.controlsEnabled) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && widget.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onUserInteraction() {
    if (!widget.controlsEnabled || !widget.allowOverlayInteraction) return;
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _startHideTimer();
  }

  @override
  void didUpdateWidget(covariant PreviewWithOverlayControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controlsEnabled) {
      _hideTimer?.cancel();
      if (_showControls) {
        setState(() => _showControls = false);
      }
      return;
    }
    if (!oldWidget.controlsEnabled && widget.controlsEnabled) {
      setState(() => _showControls = true);
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: widget.allowOverlayInteraction
          ? (_) => _onUserInteraction()
          : null,
      onEnter: widget.allowOverlayInteraction
          ? (_) => _onUserInteraction()
          : null,
      child: GestureDetector(
        onTap: widget.allowOverlayInteraction
            ? () {
                _onUserInteraction();
              }
            : null,
        child: Stack(
          children: [
            // 1. Video Preview
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.scrim,
                child: widget.preview,
              ),
            ),

            // 2. Overlay Controls
            Positioned.fill(
              child: IgnorePointer(
                ignoring:
                    !widget.controlsEnabled || !widget.allowOverlayInteraction,
                child: AnimatedOpacity(
                  opacity: widget.controlsEnabled && _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _PlayPauseButton(
                        isPlaying: widget.isPlaying,
                        onPressed: () {
                          _onUserInteraction();
                          widget.onPlayPause(!widget.isPlaying);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({required this.isPlaying, required this.onPressed});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isPlaying ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.scrim.withValues(alpha: _isHovering ? 0.6 : 0.4),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withValues(
                alpha: _isHovering ? 0.5 : 0.2,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _controller,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
