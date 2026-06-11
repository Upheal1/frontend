import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AvatarUnlockOverlay {
  static Future<void> show(
    BuildContext context, {
    required String avatarName,
    required VoidCallback onEquip,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AvatarUnlockDialog(
          avatarName: avatarName,
          onEquip: onEquip,
        );
      },
    );
  }
}

class _AvatarUnlockDialog extends StatelessWidget {
  final String avatarName;
  final VoidCallback onEquip;

  const _AvatarUnlockDialog({
    required this.avatarName,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEW AVATAR UNLOCKED',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text('🎭', style: TextStyle(fontSize: 32)),
              ).animate().flipV(
                    duration: 300.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 14),
              Text(
                avatarName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You unlocked a new companion for your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEquip();
                  },
                  child: const Text(
                    'Equip Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1, 1),
        duration: 240.ms,
        curve: Curves.easeOutBack);
  }
}
