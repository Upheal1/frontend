import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_unlock_config.dart';

class AvatarProgressionProvider extends ChangeNotifier {
  static const _prefsKeyUnlocked = 'avatar_unlocked';
  static const _prefsKeyEquipped = 'avatar_equipped';

  Set<String> _unlockedSrcs = {};
  String? _equippedSrc;

  Set<String> get unlockedSrcs => Set.unmodifiable(_unlockedSrcs);
  String? get equippedSrc => _equippedSrc;

  bool isUnlocked(String src) => _unlockedSrcs.contains(src);
  bool isUnlockableAt(int level) => AvatarUnlockConfig.all.any(
        (a) => a.unlockLevel == level,
      );

  List<AvatarUnlockConfig> get unlockedAvatars =>
      AvatarUnlockConfig.all.where((a) => _unlockedSrcs.contains(a.src)).toList();

  AvatarUnlockConfig? get equippedAvatar {
    if (_equippedSrc == null) return null;
    try {
      return AvatarUnlockConfig.all.firstWhere((a) => a.src == _equippedSrc);
    } catch (_) {
      return null;
    }
  }

  Future<void> load({int currentLevel = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKeyUnlocked) ?? [];
    _unlockedSrcs = raw.toSet();
    _equippedSrc = prefs.getString(_prefsKeyEquipped);

    final newlyUnlocked = checkAndUnlock(currentLevel);
    if (newlyUnlocked.isNotEmpty) {
      await _persistUnlocked();
    }

    if (_unlockedSrcs.isEmpty) {
      _unlock(AvatarUnlockConfig.all.first.src, save: true);
    }

    if (_equippedSrc == null || !_unlockedSrcs.contains(_equippedSrc)) {
      _equippedSrc = AvatarUnlockConfig.all.first.src;
      await _persistEquipped();
    }

    notifyListeners();
  }

  /// Lightweight sync: checks current level and unlocks any new avatars
  /// without doing I/O. Call this when UserModel notifies a change.
  /// Returns newly unlocked configs for celebration.
  List<AvatarUnlockConfig> syncWithLevel(int currentLevel) {
    final newly = checkAndUnlock(currentLevel);
    if (newly.isNotEmpty) {
      _persistUnlocked();
      notifyListeners();
    }
    return newly;
  }

  /// Checks current level against unlock thresholds and unlocks any new
  /// avatars. Returns the list of newly unlocked configs so callers can
  /// trigger celebrations.
  List<AvatarUnlockConfig> checkAndUnlock(int currentLevel) {
    final newlyUnlocked = <AvatarUnlockConfig>[];
    for (final avatar in AvatarUnlockConfig.all) {
      if (currentLevel >= avatar.unlockLevel &&
          !_unlockedSrcs.contains(avatar.src)) {
        _unlockedSrcs = {..._unlockedSrcs, avatar.src};
        newlyUnlocked.add(avatar);
      }
    }
    return newlyUnlocked;
  }

  bool unlock(String src) {
    if (_unlockedSrcs.contains(src)) return false;
    _unlock(src, save: true);
    return true;
  }

  void _unlock(String src, {required bool save}) {
    _unlockedSrcs = {..._unlockedSrcs, src};
    if (save) {
      _persistUnlocked();
    }
  }

  void equip(String src) {
    if (!_unlockedSrcs.contains(src)) return;
    _equippedSrc = src;
    _persistEquipped();
    notifyListeners();
  }

  Future<void> _persistUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyUnlocked, _unlockedSrcs.toList());
  }

  Future<void> _persistEquipped() async {
    final prefs = await SharedPreferences.getInstance();
    if (_equippedSrc != null) {
      await prefs.setString(_prefsKeyEquipped, _equippedSrc!);
    }
  }
}
