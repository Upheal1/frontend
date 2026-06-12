import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../models/notification_types.dart';
import '../navigation/navigation_helpers.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../constants/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings _settings = NotificationSettings.defaults;
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSettings();
    await _checkPermission();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      
      if (settingsJson != null && settingsJson.isNotEmpty) {
        try {
          final json = jsonDecode(settingsJson);
          setState(() {
            _settings = NotificationSettings.fromJson(json);
          });
        } catch (e) {
          debugPrint('Error parsing notification settings: $e');
          setState(() {
            _settings = NotificationSettings.defaults;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings',
        jsonEncode(_settings.toJson()),
      );
      
      if (_settings.enabled && _settings.summaryEnabled) {
        await _scheduleDailySummary();
      } else {
        await NotificationService.cancelNotification(5001);
      }
      
      debugPrint('Notification settings saved successfully');
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _scheduleDailySummary() async {
    try {
      await NotificationService.scheduleDailySummary(
        id: 5001,
        scheduledTime: _settings.summaryTime,
      );
      debugPrint('Daily summary scheduled for ${_settings.summaryTime}');
    } catch (e) {
      debugPrint('Error scheduling daily summary: $e');
    }
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await NotificationService.areNotificationsEnabled();
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
        });
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await NotificationService.requestPermissions();
      if (mounted) {
        setState(() {
          _hasPermission = granted;
        });
        
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please enable notifications in system settings',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  void _updateSettings(NotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _saveSettings();
  }

  Future<void> _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.summaryTime.hour,
        minute: _settings.summaryTime.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(
                    primary: Color(0xFF8B5CF6),
                    onPrimary: Colors.white,
                    surface: Color(0xFF2A2A2A),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF8B5CF6),
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      final now = DateTime.now();
      _updateSettings(_settings.copyWith(
        summaryTime: DateTime(now.year, now.month, now.day, time.hour, time.minute),
      ));
    }
  }

  Future<void> _testNotification() async {
    HapticFeedback.mediumImpact();
    
    try {
      await NotificationService.showNotification(
        title: '🔔 Test Notification',
        body: 'Your notification settings are working correctly!',
        payload: 'test:notification',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Test notification sent!',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Failed to send notification. Check permissions.',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: tokens.primaryText,
          ),
          onPressed: () => safeGoBack(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            color: tokens.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                ),
              ),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.pageGradient),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading settings...',
                      style: GoogleFonts.inter(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_hasPermission) _buildPermissionCard(isDark),
                    _buildMasterToggle(isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Notification Types', isDark),
                    const SizedBox(height: 12),
                    _buildNotificationTypesCard(isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Warning Threshold', isDark),
                    const SizedBox(height: 12),
                    _buildThresholdCard(isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Daily Summary', isDark),
                    const SizedBox(height: 12),
                    _buildSummaryTimeCard(isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Sound & Haptics', isDark),
                    const SizedBox(height: 12),
                    _buildSoundVibrationCard(isDark),
                    const SizedBox(height: 32),
                    _buildTestButton(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermissionCard(bool isDark) {
    final tokens = Theme.of(context).upHealHome;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.bellOff, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications Disabled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap enable to receive app notifications',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: tokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _requestPermission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Enable',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildMasterToggle(bool isDark) {
    final tokens = Theme.of(context).upHealHome;

    return Container(
      decoration: BoxDecoration(
        gradient: _settings.enabled
            ? LinearGradient(
                colors: [
                  AppColors.purple.withValues(alpha: 0.2),
                  AppColors.purple.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: _settings.enabled ? null : tokens.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _settings.enabled
              ? AppColors.purple.withValues(alpha: 0.3)
              : tokens.cardBorder,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          'Enable Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: tokens.primaryText,
          ),
        ),
        subtitle: Text(
          _settings.enabled ? 'You\'ll receive all notifications' : 'Turn on to receive notifications',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: tokens.secondaryText,
          ),
        ),
        value: _settings.enabled,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          _updateSettings(_settings.copyWith(enabled: value));
        },
        activeThumbColor: AppColors.purple,
        activeTrackColor: AppColors.purple.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: tokens.primaryText,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNotificationTypesCard(bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    final isEnabled = _settings.enabled;
    
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: [
          _buildToggleTile(
            title: 'Usage Warnings',
            subtitle: 'Alert when approaching limits',
            icon: LucideIcons.alertTriangle,
            iconColor: Colors.orange,
            value: _settings.warningsEnabled,
            enabled: isEnabled,
            onChanged: (value) => _updateSettings(_settings.copyWith(warningsEnabled: value)),
            isDark: isDark,
          ),
          _divider(isDark),
          _buildToggleTile(
            title: 'Limit Reached',
            subtitle: 'Notify when time limit is reached',
            icon: LucideIcons.ban,
            iconColor: Colors.red,
            value: _settings.limitsEnabled,
            enabled: isEnabled,
            onChanged: (value) => _updateSettings(_settings.copyWith(limitsEnabled: value)),
            isDark: isDark,
          ),
          _divider(isDark),
          _buildToggleTile(
            title: 'Daily Summary',
            subtitle: 'Evening recap of your progress',
            icon: LucideIcons.barChart3,
            iconColor: Colors.blue,
            value: _settings.summaryEnabled,
            enabled: isEnabled,
            onChanged: (value) => _updateSettings(_settings.copyWith(summaryEnabled: value)),
            isDark: isDark,
          ),
          _divider(isDark),
          _buildToggleTile(
            title: 'Achievements',
            subtitle: 'Celebrate your accomplishments',
            icon: LucideIcons.trophy,
            iconColor: Colors.amber,
            value: _settings.achievementsEnabled,
            enabled: isEnabled,
            onChanged: (value) => _updateSettings(_settings.copyWith(achievementsEnabled: value)),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }

  Widget _divider(bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    return Divider(
      height: 1,
      color: tokens.dividerColor,
      indent: 68,
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required bool enabled,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    final tokens = Theme.of(context).upHealHome;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: enabled ? tokens.primaryText : tokens.faintText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: tokens.secondaryText,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: value && enabled,
          onChanged: enabled ? (v) { HapticFeedback.selectionClick(); onChanged(v); } : null,
          activeThumbColor: AppColors.purple,
          activeTrackColor: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildThresholdCard(bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    final isEnabled = _settings.enabled;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.layers,
                color: isEnabled ? AppColors.purple : tokens.faintText,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Warn at ${_settings.warningThreshold}% of limit',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: tokens.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Get notified when you reach this percentage of your app limit',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: tokens.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildThresholdChip(80, isEnabled, isDark),
              const SizedBox(width: 12),
              _buildThresholdChip(90, isEnabled, isDark),
              const SizedBox(width: 12),
              _buildThresholdChip(95, isEnabled, isDark),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildThresholdChip(int threshold, bool isEnabled, bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    final isSelected = _settings.warningThreshold == threshold;
    
    return Expanded(
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                _updateSettings(_settings.copyWith(warningThreshold: threshold));
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.purple
                : tokens.trackColor,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: tokens.cardBorder),
          ),
          child: Center(
            child: Text(
              '$threshold%',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isSelected
                    ? Colors.white
                    : (isEnabled ? tokens.secondaryText : tokens.faintText),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTimeCard(bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    final isEnabled = _settings.enabled && _settings.summaryEnabled;
    final timeString = TimeOfDay(
      hour: _settings.summaryTime.hour,
      minute: _settings.summaryTime.minute,
    ).format(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.clock, color: Colors.blue, size: 22),
        ),
        title: Text(
          'Summary Time',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: tokens.primaryText,
          ),
        ),
        subtitle: Text(
          isEnabled ? 'Daily at $timeString' : 'Disabled',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: tokens.secondaryText,
          ),
        ),
        trailing: GestureDetector(
          onTap: isEnabled
              ? () {
                  HapticFeedback.selectionClick();
                  _showTimePicker();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.purple.withValues(alpha: 0.1)
                  : tokens.faintText.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              timeString,
              style: GoogleFonts.inter(
                color: isEnabled ? AppColors.purple : tokens.faintText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 250.ms);
  }

  Widget _buildSoundVibrationCard(bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    final isEnabled = _settings.enabled;
    
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Sound',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: tokens.primaryText,
              ),
            ),
            secondary: Icon(
              LucideIcons.volume2,
              color: tokens.secondaryText,
            ),
            value: _settings.soundEnabled,
            onChanged: isEnabled
                ? (value) {
                    HapticFeedback.selectionClick();
                    _updateSettings(_settings.copyWith(soundEnabled: value));
                  }
                : null,
            activeThumbColor: AppColors.purple,
            activeTrackColor: AppColors.purple.withValues(alpha: 0.3),
          ),
          Divider(
            height: 1,
            color: tokens.dividerColor,
            indent: 16,
          ),
          SwitchListTile(
            title: Text(
              'Vibration',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: tokens.primaryText,
              ),
            ),
            secondary: Icon(
              LucideIcons.smartphone,
              color: tokens.secondaryText,
            ),
            value: _settings.vibrationEnabled,
            onChanged: isEnabled
                ? (value) {
                    HapticFeedback.selectionClick();
                    _updateSettings(_settings.copyWith(vibrationEnabled: value));
                  }
                : null,
            activeThumbColor: AppColors.purple,
            activeTrackColor: AppColors.purple.withValues(alpha: 0.3),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildTestButton(bool isDark) {
    final tokens = Theme.of(context).upHealHome;
    final isEnabled = _settings.enabled;
    
    return GestureDetector(
      onTap: isEnabled ? _testNotification : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? tokens.accentGradient
              : null,
          color: isEnabled ? null : tokens.trackColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bellRing,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Send Test Notification',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 350.ms);
  }
}