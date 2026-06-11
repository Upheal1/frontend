import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';

/// Embedded 3D viewer for the Traveler GLB using Google's `<model-viewer>` via [o3d].
///
/// Place [TravelerViewer.defaultAssetPath] under `assets/` and declare it in `pubspec.yaml`.
/// On **web**, `web/index.html` must load `model-viewer.min.js` (see o3d README).
/// On **Android 9+**, cleartext to the package's localhost proxy must be allowed.
class TravelerViewer extends StatefulWidget {
  const TravelerViewer({
    super.key,
    this.assetPath = defaultAssetPath,
    this.height = 280,
    this.backgroundColor,
    this.progressBarColor = Colors.transparent,
  });

  /// Default matches [pubspec.yaml] / project layout: `assets/traveler.glb`.
  static const String defaultAssetPath = 'assets/traveler.glb';

  /// Path registered as a Flutter asset (not a filesystem path).
  final String assetPath;

  /// Viewport height in logical pixels.
  final double height;

  /// WebView / scene background: use [Colors.transparent] to show whatever is behind,
  /// or pass [Theme.of(context).scaffoldBackgroundColor] to blend with the screen.
  final Color? backgroundColor;

  /// Hides model-viewer's internal progress bar (we use our own overlay).
  final Color? progressBarColor;

  @override
  State<TravelerViewer> createState() => _TravelerViewerState();
}

class _TravelerViewerState extends State<TravelerViewer> {
  /// Stable DOM id → matches injected JS (`o3d` + id) used by [O3DController.executeCustomJsCodeWithResult].
  static const String _viewerId = 'uphealTraveler';

  late O3DController _controller;
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  Timer? _webFallbackTimer;

  bool _ready = false;
  bool _failed = false;
  int _reloadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _attachController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginLoadingWatch());
  }

  void _attachController() {
    _controller = O3DController();
    _controller.logger = _onPackageLog;
  }

  /// Surfaces only serious failures from o3d's localhost proxy / asset pipeline (not generic debug text).
  void _onPackageLog(Object data) {
    final msg = data.toString().toLowerCase();
    if (msg.contains('error in _readasset') ||
        msg.contains('init proxy error') ||
        msg.contains('data is empty')) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _beginLoadingWatch() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    _webFallbackTimer?.cancel();

    // Hard timeout — user sees retry UI if the model never becomes interactive.
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!mounted || _ready || _failed) return;
      setState(() => _failed = true);
    });

    if (kIsWeb) {
      // On web, controller evaluation tracks the same `<model-viewer>` element; add a soft cap so the
      // spinner cannot stick forever if polling misses.
      _webFallbackTimer = Timer(const Duration(seconds: 8), () {
        if (!mounted || _ready || _failed) return;
        setState(() => _ready = true);
      });
    }

    _pollTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      unawaited(_pollModelLoaded());
    });
  }

  Future<void> _pollModelLoaded() async {
    if (!mounted || _ready || _failed) return;
    try {
      final code = '''
(function () {
  try {
    var el = document.getElementById('$_viewerId') || document.querySelector('#$_viewerId');
    return !!(el && el.loaded === true);
  } catch (e) {
    return false;
  }
})()
''';
      final result = await _controller.executeCustomJsCodeWithResult(code);
      if (_truthy(result) && mounted) {
        setState(() {
          _ready = true;
          _pollTimer?.cancel();
          _timeoutTimer?.cancel();
          _webFallbackTimer?.cancel();
        });
      }
    } catch (_) {
      // WebView / eval not ready yet — keep polling until timeout.
    }
  }

  bool _truthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  void _retry() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    _webFallbackTimer?.cancel();
    setState(() {
      _failed = false;
      _ready = false;
      _reloadGeneration++;
      _attachController();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginLoadingWatch());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    _webFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Colors.transparent;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // RepaintBoundary limits unnecessary repaints when the rest of the Home screen animates.
            RepaintBoundary(
              child: O3D.asset(
                key: ValueKey<String>('traveler_o3d_$_reloadGeneration'),
                id: _viewerId,
                src: widget.assetPath,
                controller: _controller,
                backgroundColor: bg,
                progressBarColor: widget.progressBarColor,

                // Interaction: drag/touch orbits the camera (when camera-controls is on).
                cameraControls: true,
                touchAction: TouchAction.none,
                disablePan: true,
                disableZoom: true,
                orbitSensitivity: 1,

                // No auto-rotate — avatar is static until the user presses & drags.
                autoRotate: false,

                interactionPrompt: InteractionPrompt.none,

                // Framing zoomed out so full character stays in view.
                cameraOrbit: CameraOrbit(0, 65, 4.0),

                loading: Loading.eager,
                reveal: Reveal.auto,

                // Softer lighting without an HDR skybox; cheaper than full IBL for many GLBs.
                environmentImage: 'neutral',
                exposure: 1,
                shadowIntensity: kIsWeb ? 0.45 : 0.28,
                interpolationDecay: 120,

                alt: 'Traveler companion character for UpHeal',
              ),
            ),

            if (!_ready && !_failed)
              Positioned.fill(
                child: ColoredBox(
                  // Subtle veil over the WebView while GLB bytes stream in / shaders compile.
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.82),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),

            if (_failed)
              Positioned.fill(
                child: Material(
                  color: scheme.surface.withValues(alpha: 0.94),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.view_in_ar_outlined,
                          size: 40,
                          color: scheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load the 3D character.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check that ${widget.assetPath} exists and is listed under flutter/assets.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
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
