import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/focus_session_model.dart';
import '../models/hive/focus_session_history.dart';

class PremiumFocusTimerScreen extends StatefulWidget {
  const PremiumFocusTimerScreen({super.key});

  @override
  State<PremiumFocusTimerScreen> createState() =>
      _PremiumFocusTimerScreenState();
}

class _PremiumFocusTimerScreenState extends State<PremiumFocusTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  bool _sessionEnded = false;
  FocusSessionState? _listenedState;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<FocusSessionState>();
      _listenedState = state;
      state.addListener(_onStateChanged);
    });
  }

  void _onStateChanged() {
    if (_listenedState == null) return;
    final hasSession = _listenedState!.currentSession != null;
    if (!hasSession && !_sessionEnded) {
      setState(() => _sessionEnded = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _listenedState?.removeListener(_onStateChanged);
    _gradientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onClose() {
    HapticFeedback.lightImpact();
    final state = context.read<FocusSessionState>();
    if (state.isActive || state.isPaused) {
      state.pauseSession();
    }
    Navigator.pop(context);
  }

  void _onComplete() {
    HapticFeedback.mediumImpact();
    final state = context.read<FocusSessionState>();
    state.stopSession();
    Navigator.pop(context);
  }

  void _onShortBreak() {
    HapticFeedback.mediumImpact();
    final state = context.read<FocusSessionState>();
    state.completeSession();
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<FocusSessionState>().startSession(
            type: FocusSessionType.shortBreak,
          );
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    final state = context.read<FocusSessionState>();
    if (state.isActive) {
      state.pauseSession();
    } else if (state.isPaused) {
      state.resumeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? <Color>[
            const Color(0xFF1A1025),
            const Color(0xFF2D1B4E),
            const Color(0xFF1B1B2E),
          ]
        : <Color>[
            const Color(0xFFEDE4F3),
            const Color(0xFFDCC8EC),
            const Color(0xFFF3EAF8),
          ];

    return Scaffold(
      body: Consumer<FocusSessionState>(
        builder: (context, state, child) {
          final hasSession = state.currentSession != null;
          final showComplete = _sessionEnded;

          return Stack(
            children: [
              AnimatedBuilder(
                animation: _gradientController,
                builder: (context, _) {
                  final dx =
                      0.5 + 0.35 * math.sin(_gradientController.value * 2 * math.pi);
                  final dy =
                      0.5 + 0.35 * math.cos(_gradientController.value * 2 * math.pi);
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment(dx, dy),
                        colors: gradientColors,
                      ),
                    ),
                  );
                },
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          Text(
                            'Focus Session',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.white.withAlpha(180),
                                size: 22,
                              ),
                              onPressed: _onClose,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: hasSession ? _togglePause : null,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = state.isActive ? _pulseController.value : 0.0;
                          return Transform.scale(
                            scale: 1.0 + 0.025 * pulse,
                            child: Container(
                              width: 270,
                              height: 270,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withAlpha(90),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? const Color(0xFF7C3AED).withAlpha(50)
                                        : const Color(0xFF9B6EE6).withAlpha(60),
                                    blurRadius: 50,
                                    spreadRadius: state.isActive ? 15 : 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withAlpha(10),
                                    blurRadius: 70,
                                    spreadRadius: 25,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Remaining Time',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withAlpha(180),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    hasSession
                                        ? state.currentSession!.formattedTime
                                        : '00:00',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: hasSession ? 1.0 : 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(35),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        state.isPaused ? 'Paused' : 'Tap to pause',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withAlpha(200),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withAlpha(35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed:
                                          hasSession ? _onComplete : null,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.white.withAlpha(120),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(26),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      child: Text(
                                        'Complete',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed:
                                          hasSession ? _onShortBreak : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2D2D2D),
                                        foregroundColor: Colors.white,
                                        elevation: 6,
                                        shadowColor:
                                            Colors.black.withAlpha(70),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(26),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      child: Text(
                                        'Short Break',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
              if (showComplete)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + 0.05 * _pulseController.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981).withAlpha(50),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Session Complete',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
