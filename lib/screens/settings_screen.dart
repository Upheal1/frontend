import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../avatar/services/avatar_provider.dart';
import '../constants/app_colors.dart';
import '../models/auth_model.dart';
import '../models/theme_model.dart';
import '../models/user_model.dart';
import '../navigation/app_routes.dart';
import '../navigation/navigation_helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = AppSettings(
        profileVisibility: prefs.getString('profile_visibility') ?? 'friends',
        showBadges: prefs.getBool('show_badges') ?? true,
        showLevel: prefs.getBool('show_level') ?? true,
        activityTracking: prefs.getBool('activity_tracking') ?? true,
        dailyJournalGoal: prefs.getInt('daily_journal_goal') ?? 1,
        dailyFocusGoal: prefs.getInt('daily_focus_goal') ?? 30,
        checkInTime: prefs.getString('check_in_time') ?? '09:00',
        crisisResourcesEnabled: prefs.getBool('crisis_resources') ?? true,
        language: prefs.getString('language') ?? 'en',
        textSize: prefs.getDouble('text_size') ?? 1.0,
        reducedMotion: prefs.getBool('reduced_motion') ?? false,
        isPremium: prefs.getBool('is_premium') ?? false,
        dailyCheckIn: prefs.getBool('daily_check_in') ?? true,
        milestoneAlerts: prefs.getBool('milestone_alerts') ?? true,
        communityActivity: prefs.getBool('community_activity') ?? false,
        aiTherapistReminders: prefs.getBool('ai_therapist_reminders') ?? true,
        therapistReminders: prefs.getBool('therapist_reminders') ?? true,
        streakWarnings: prefs.getBool('streak_warnings') ?? true,
      );
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_visibility', _settings.profileVisibility);
    await prefs.setBool('show_badges', _settings.showBadges);
    await prefs.setBool('show_level', _settings.showLevel);
    await prefs.setBool('activity_tracking', _settings.activityTracking);
    await prefs.setInt('daily_journal_goal', _settings.dailyJournalGoal);
    await prefs.setInt('daily_focus_goal', _settings.dailyFocusGoal);
    await prefs.setString('check_in_time', _settings.checkInTime);
    await prefs.setBool('crisis_resources', _settings.crisisResourcesEnabled);
    await prefs.setString('language', _settings.language);
    await prefs.setDouble('text_size', _settings.textSize);
    await prefs.setBool('reduced_motion', _settings.reducedMotion);
    await prefs.setBool('is_premium', _settings.isPremium);
    await prefs.setBool('daily_check_in', _settings.dailyCheckIn);
    await prefs.setBool('milestone_alerts', _settings.milestoneAlerts);
    await prefs.setBool('community_activity', _settings.communityActivity);
    await prefs.setBool('ai_therapist_reminders', _settings.aiTherapistReminders);
    await prefs.setBool('therapist_reminders', _settings.therapistReminders);
    await prefs.setBool('streak_warnings', _settings.streakWarnings);
  }

  Future<void> _updateSetting(void Function(AppSettings settings) update) async {
    setState(() {
      update(_settings);
    });
    await _saveSettings();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved', style: GoogleFonts.inter()),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background =
        isDark ? const Color(0xFF0B0D12) : const Color(0xFFFDFCFA);

    return Scaffold(
      backgroundColor: background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        _buildGamificationCard(context),
                        const SizedBox(height: 20),
                        _buildSection(
                          context,
                          title: 'Account',
                          icon: LucideIcons.user,
                          children: <Widget>[_buildAccountTile(context)],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context,
                          title: 'Notifications',
                          icon: LucideIcons.bell,
                          children: <Widget>[
                            _buildNotificationTile(
                              context,
                              'Daily Check-in',
                              'Reminds you to check in daily',
                              _settings.dailyCheckIn,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.dailyCheckIn = value,
                              ),
                            ),
                            _buildNotificationTile(
                              context,
                              'Roadmap Milestones',
                              'Alerts when you reach milestones',
                              _settings.milestoneAlerts,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.milestoneAlerts = value,
                              ),
                            ),
                            _buildNotificationTile(
                              context,
                              'Community Activity',
                              'Posts, comments, and group updates',
                              _settings.communityActivity,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.communityActivity = value,
                              ),
                            ),
                            _buildNotificationTile(
                              context,
                              'AI Therapist Sessions',
                              'Reminders for AI chat sessions',
                              _settings.aiTherapistReminders,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.aiTherapistReminders = value,
                              ),
                            ),
                            _buildNotificationTile(
                              context,
                              'Therapist Appointments',
                              'Booked appointment reminders',
                              _settings.therapistReminders,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.therapistReminders = value,
                              ),
                            ),
                            _buildNotificationTile(
                              context,
                              'Streak Warnings',
                              'Do not break your streak reminders',
                              _settings.streakWarnings,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.streakWarnings = value,
                              ),
                            ),
                            _buildTimePickerTile(
                              context,
                              'Check-in Time',
                              _settings.checkInTime,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context,
                          title: 'Privacy & Data',
                          icon: LucideIcons.shield,
                          children: <Widget>[
                            _buildPrivacyTile(
                              context,
                              'Profile Visibility',
                              _settings.profileVisibility,
                              () => _showVisibilityPicker(context),
                            ),
                            _buildToggleTile(
                              context,
                              'Show Badges on Profile',
                              _settings.showBadges,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.showBadges = value,
                              ),
                            ),
                            _buildToggleTile(
                              context,
                              'Show Level on Profile',
                              _settings.showLevel,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.showLevel = value,
                              ),
                            ),
                            _buildToggleTile(
                              context,
                              'Activity Tracking',
                              _settings.activityTracking,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.activityTracking = value,
                              ),
                            ),
                            _buildActionTile(
                              context,
                              'Export My Data',
                              'Download your data',
                              LucideIcons.download,
                              () => _exportData(context),
                            ),
                            _buildActionTile(
                              context,
                              'Delete Account',
                              'Permanently delete your account',
                              LucideIcons.trash2,
                              () => _showDeleteConfirmation(context),
                              isDestructive: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context,
                          title: 'App Preferences',
                          icon: LucideIcons.settings,
                          children: <Widget>[
                            _buildThemeTile(context),
                            _buildLanguageTile(context),
                            _buildTextSizeTile(context),
                            _buildToggleTile(
                              context,
                              'Reduced Motion',
                              _settings.reducedMotion,
                              (bool value) => _updateSetting(
                                (AppSettings s) => s.reducedMotion = value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context,
                          title: 'Wellness Goals',
                          icon: LucideIcons.target,
                          children: <Widget>[
                            _buildGoalTile(
                              context,
                              'Daily Journal Entries',
                              '${_settings.dailyJournalGoal} entries',
                              () => _showGoalPicker(context, 'journal'),
                            ),
                            _buildGoalTile(
                              context,
                              'Daily Focus Time',
                              '${_settings.dailyFocusGoal} minutes',
                              () => _showGoalPicker(context, 'focus'),
                            ),
                            _buildToggleTile(
                              context,
                              'Crisis Resources Quick Access',
                              _settings.crisisResourcesEnabled,
                              (bool value) => _updateSetting(
                                (AppSettings s) =>
                                    s.crisisResourcesEnabled = value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context,
                          title: 'Subscription',
                          icon: LucideIcons.creditCard,
                          children: <Widget>[_buildSubscriptionTile(context)],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context,
                          title: 'Support',
                          icon: LucideIcons.helpCircle,
                          children: <Widget>[
                            _buildActionTile(
                              context,
                              'Help Center / FAQs',
                              'Get help',
                              LucideIcons.bookOpen,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Contact Support',
                              'Reach our team',
                              LucideIcons.messageCircle,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Community Guidelines',
                              'Learn our rules',
                              LucideIcons.users,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Crisis Hotlines',
                              'Get emergency help',
                              LucideIcons.phone,
                              () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          context,
                          title: 'About',
                          icon: LucideIcons.info,
                          children: <Widget>[
                            _buildActionTile(
                              context,
                              'App Version',
                              '1.0.0',
                              LucideIcons.tag,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Terms of Service',
                              'Read terms',
                              LucideIcons.fileText,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Privacy Policy',
                              'Read policy',
                              LucideIcons.lock,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Licenses & Credits',
                              'Open source licenses',
                              LucideIcons.award,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Rate the App',
                              'Leave a review',
                              LucideIcons.star,
                              () {},
                            ),
                            _buildActionTile(
                              context,
                              'Share with Friends',
                              'Invite others',
                              LucideIcons.share2,
                              () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.teal.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () => safeGoBack(context),
              icon: Icon(
                LucideIcons.arrowLeft,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserModel user = context.watch<UserModel>();
    final bool profileComplete = user.username.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.compass,
                  color: AppColors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Expedition Status',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        _buildLevelBadge(
                          context,
                          'L${user.level}',
                          AppColors.purple,
                        ),
                        const SizedBox(width: 8),
                        _buildLevelBadge(
                          context,
                          '${user.xp} XP',
                          AppColors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildLevelBadge(
                          context,
                          '${user.streakDays} days',
                          AppColors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!profileComplete) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    LucideIcons.plusCircle,
                    color: AppColors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete your profile for +50 XP',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.teal),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildAccountTile(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthModel auth = context.watch<AuthModel>();
    final AvatarProvider avatar = context.watch<AvatarProvider>();
    final UserModel user = context.watch<UserModel>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.purple.withValues(alpha: 0.1),
              image: DecorationImage(
                image: AssetImage(avatar.selectedAvatarAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  auth.userName ?? user.username,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.userEmail ?? 'user@upheal.app',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => const AvatarRoute().push<void>(context),
            icon: Icon(
              LucideIcons.pencil,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            tooltip: 'Edit avatar',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(BuildContext context, String title, String time) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Text(
        time,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.teal,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () async {
        final List<String> parts = time.split(':');
        final TimeOfDay initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (picked != null) {
          final String newTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          await _updateSetting((AppSettings s) => s.checkInTime = newTime);
        }
      },
    );
  }

  Widget _buildPrivacyTile(
    BuildContext context,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value == 'public'
                ? 'Public'
                : value == 'friends'
                    ? 'Friends'
                    : 'Private',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(
    BuildContext context,
    String title,
    bool value,
    void Function(bool) onChanged,
  ) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color color = isDestructive ? AppColors.red : AppColors.teal;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.red : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      onTap: onTap,
    );
  }

  Widget _buildGoalTile(
    BuildContext context,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeModel themeModel = context.watch<ThemeModel>();
    final String currentTheme = themeModel.themeMode == ThemeMode.light
        ? 'Light'
        : themeModel.themeMode == ThemeMode.dark
            ? 'Dark'
            : 'System';

    return ListTile(
      leading: Icon(LucideIcons.moon, color: AppColors.teal, size: 20),
      title: Text(
        'Theme',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            currentTheme,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
      onTap: () => _showThemePicker(context),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: Icon(LucideIcons.globe, color: AppColors.teal, size: 20),
      title: Text(
        'Language',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _settings.language == 'en' ? 'English' : 'Arabic',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
      onTap: () => _showLanguagePicker(context),
    );
  }

  Widget _buildTextSizeTile(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: Icon(LucideIcons.type, color: AppColors.teal, size: 20),
      title: Text(
        'Text Size',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _settings.textSize == 0.8
                ? 'Small'
                : _settings.textSize == 1.0
                    ? 'Medium'
                    : 'Large',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
      onTap: () => _showTextSizePicker(context),
    );
  }

  Widget _buildSubscriptionTile(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: Icon(LucideIcons.creditCard, color: AppColors.teal, size: 20),
      title: Text(
        _settings.isPremium ? 'Premium Explorer' : 'Free Traveler',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        _settings.isPremium ? 'Active' : 'Upgrade to unlock more features',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: _settings.isPremium
              ? AppColors.green
              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: !_settings.isPremium
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Upgrade',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      onTap: () {},
    );
  }

  void _showVisibilityPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(LucideIcons.globe),
            title: Text('Public', style: GoogleFonts.inter()),
            trailing: _settings.profileVisibility == 'public'
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting(
                (AppSettings s) => s.profileVisibility = 'public',
              );
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.users),
            title: Text('Friends Only', style: GoogleFonts.inter()),
            trailing: _settings.profileVisibility == 'friends'
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting(
                (AppSettings s) => s.profileVisibility = 'friends',
              );
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.lock),
            title: Text('Private', style: GoogleFonts.inter()),
            trailing: _settings.profileVisibility == 'private'
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting(
                (AppSettings s) => s.profileVisibility = 'private',
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final ThemeModel themeModel = context.read<ThemeModel>();
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(LucideIcons.sun),
            title: Text('Light Mode', style: GoogleFonts.inter()),
            trailing: themeModel.isLightMode
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              themeModel.setLightMode();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.moon),
            title: Text('Dark Mode', style: GoogleFonts.inter()),
            trailing: themeModel.isDarkMode
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              themeModel.setDarkMode();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.smartphone),
            title: Text('System Default', style: GoogleFonts.inter()),
            trailing: themeModel.themeMode == ThemeMode.system
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              themeModel.setSystemMode();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(LucideIcons.globe),
            title: Text('English', style: GoogleFonts.inter()),
            trailing: _settings.language == 'en'
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting((AppSettings s) => s.language = 'en');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.languages),
            title: Text('Arabic', style: GoogleFonts.inter()),
            trailing: _settings.language == 'ar'
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting((AppSettings s) => s.language = 'ar');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showTextSizePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text('Small', style: GoogleFonts.inter()),
            trailing: _settings.textSize == 0.8
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting((AppSettings s) => s.textSize = 0.8);
            },
          ),
          ListTile(
            title: Text('Medium', style: GoogleFonts.inter()),
            trailing: _settings.textSize == 1.0
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting((AppSettings s) => s.textSize = 1.0);
            },
          ),
          ListTile(
            title: Text('Large', style: GoogleFonts.inter()),
            trailing: _settings.textSize == 1.2
                ? Icon(Icons.check, color: AppColors.teal)
                : null,
            onTap: () {
              Navigator.pop(context);
              _updateSetting((AppSettings s) => s.textSize = 1.2);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showGoalPicker(BuildContext context, String type) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        final List<String> items = type == 'journal'
            ? <int>[1, 2, 3, 4, 5].map((int i) => '$i entries').toList()
            : <int>[15, 30, 45, 60, 90]
                .map((int i) => '$i minutes')
                .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: items.asMap().entries.map((entry) {
            return ListTile(
              title: Text(entry.value, style: GoogleFonts.inter()),
              trailing: Icon(Icons.check, color: AppColors.teal),
              onTap: () {
                Navigator.pop(context);
                if (type == 'journal') {
                  _updateSetting(
                    (AppSettings s) => s.dailyJournalGoal = entry.key + 1,
                  );
                } else {
                  _updateSetting(
                    (AppSettings s) =>
                        s.dailyFocusGoal = int.parse(entry.value.split(' ')[0]),
                  );
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing data export...', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: GoogleFonts.inter(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account deletion initiated',
                    style: GoogleFonts.inter(),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class AppSettings {
  AppSettings({
    this.profileVisibility = 'friends',
    this.showBadges = true,
    this.showLevel = true,
    this.activityTracking = true,
    this.dailyJournalGoal = 1,
    this.dailyFocusGoal = 30,
    this.checkInTime = '09:00',
    this.crisisResourcesEnabled = true,
    this.language = 'en',
    this.textSize = 1.0,
    this.reducedMotion = false,
    this.isPremium = false,
    this.dailyCheckIn = true,
    this.milestoneAlerts = true,
    this.communityActivity = false,
    this.aiTherapistReminders = true,
    this.therapistReminders = true,
    this.streakWarnings = true,
  });

  String profileVisibility;
  bool showBadges;
  bool showLevel;
  bool activityTracking;
  int dailyJournalGoal;
  int dailyFocusGoal;
  String checkInTime;
  bool crisisResourcesEnabled;
  String language;
  double textSize;
  bool reducedMotion;
  bool isPremium;
  bool dailyCheckIn;
  bool milestoneAlerts;
  bool communityActivity;
  bool aiTherapistReminders;
  bool therapistReminders;
  bool streakWarnings;
}
