import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/streak_model.dart';
import '../../services/reward_orchestrator.dart' as rewards;

import '../../avatar/services/avatar_progression_provider.dart';
import 'avatar_unlock_overlay.dart';
import 'badge_unlock_overlay.dart';
import 'level_up_overlay.dart';
import 'streak_milestone_overlay.dart';
import 'xp_burst_overlay.dart';

/// Listens to [RewardOrchestrator] and shows reward overlays sequentially.
///
/// - Checks the queue after each frame.
/// - Consumes at most one reward per tick.
/// - Waits 300ms between rewards so overlays don't stack simultaneously.
class RewardListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const RewardListener({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  @override
  State<RewardListener> createState() => _RewardListenerState();
}

class _RewardListenerState extends State<RewardListener> {
  bool _isProcessing = false;
  Timer? _gapTimer;

  BuildContext get _overlayContext =>
      widget.navigatorKey?.currentContext ?? context;

  @override
  void dispose() {
    _gapTimer?.cancel();
    super.dispose();
  }

  void _scheduleCheck() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _processOne();
    });
  }

  void _processOne() {
    if (!mounted || _isProcessing) return;

    final orchestrator = context.read<rewards.RewardOrchestrator>();
    if (!orchestrator.hasPending) return;

    _isProcessing = true;

    final event = orchestrator.consumeNext();
    if (event == null) {
      _isProcessing = false;
      return;
    }

    // Route to appropriate overlay.
    if (event is rewards.XpGained) {
      XpBurstOverlay.show(
        _overlayContext,
        amount: event.amount,
        oldXp: (event.newTotal - event.amount).clamp(0, event.newTotal),
        newXp: event.newTotal,
        xpNeeded: event.xpNeeded,
        level: event.level,
      );
    } else if (event is rewards.LevelUp) {
      LevelUpOverlay.show(
        _overlayContext,
        newLevel: event.newLevel,
        title: event.newTitle,
      );
    } else if (event is rewards.StreakMilestone) {
      final freezeTokens = context.read<StreakState>().freezeTokens;
      StreakMilestoneOverlay.show(
        _overlayContext,
        days: event.days,
        label: event.label,
        freezeTokens: freezeTokens,
      );
    } else if (event is rewards.BadgeUnlocked) {
      BadgeUnlockOverlay.show(
        _overlayContext,
        badgeId: event.badgeId,
        badgeName: event.badgeName,
        emoji: event.emoji,
      );
    } else if (event is rewards.UrgeResisted) {
      ScaffoldMessenger.of(_overlayContext).showSnackBar(
        SnackBar(
          content: Text(
            'You held off for ${event.secondsHeld} seconds. That\'s strength.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (event is rewards.AvatarUnlocked) {
      AvatarUnlockOverlay.show(
        _overlayContext,
        avatarName: event.avatarName,
        onEquip: () {
          context.read<AvatarProgressionProvider>().equip(event.avatarSrc);
        },
      );
    }

    // After a small gap, allow processing the next event.
    _gapTimer?.cancel();
    _gapTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _isProcessing = false;
      _scheduleCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<rewards.RewardOrchestrator>(
      builder: (context, orchestrator, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_isProcessing) return;
          if (!orchestrator.hasPending) return;
          _processOne();
        });

        return widget.child;
      },
    );
  }
}
