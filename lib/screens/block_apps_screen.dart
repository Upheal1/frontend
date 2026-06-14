import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/drawer_menu_button.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';

class BlockAppsScreen extends StatefulWidget {
  const BlockAppsScreen({Key? key}) : super(key: key);

  @override
  State<BlockAppsScreen> createState() => _BlockAppsScreenState();
}

class _BlockAppsScreenState extends State<BlockAppsScreen> {
  static const platform = MethodChannel('com.appguard.native_calls');

  static List<Map<String, dynamic>>? _cachedInstalledApps;
  static Map<String, Uint8List?> _cachedAppIcons = {};

  List<Map<String, dynamic>> installedApps = [];
  Set<String> blockedPackages = {};
  bool isLoading = true;
  bool hasUsagePermission = false;
  bool hasAccessibilityPermission = false;
  bool isBlockingActive = false;
  String searchQuery = '';
  Map<String, Uint8List?> appIcons = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkPermissions();

    if (_cachedInstalledApps != null) {
      setState(() {
        installedApps = _cachedInstalledApps!;
        appIcons = Map<String, Uint8List?>.from(_cachedAppIcons);
        isLoading = false;
      });
    } else {
      await _loadInstalledApps();
    }

    await _loadBlockedApps();

    if (_cachedInstalledApps == null && installedApps.isNotEmpty) {
      _saveToCache();
      setState(() => isLoading = false);
    }
  }

  void _saveToCache() {
    _cachedInstalledApps = List<Map<String, dynamic>>.from(installedApps);
    _cachedAppIcons = Map<String, Uint8List?>.from(appIcons);
  }

  Future<void> _refreshApps() async {
    setState(() => _isRefreshing = true);
    await _loadInstalledApps();
    await _loadBlockedApps();
    _saveToCache();
    setState(() => _isRefreshing = false);
  }

  Future<void> _checkPermissions() async {
    try {
      final usagePermission =
          await platform.invokeMethod('checkUsageStatsPermission');
      final accessibilityPermission =
          await platform.invokeMethod('checkAccessibilityPermission');

      setState(() {
        hasUsagePermission = usagePermission ?? false;
        hasAccessibilityPermission = accessibilityPermission ?? false;
      });
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  Future<void> _requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestUsageStatsPermission');
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();
    } catch (e) {
      print('Error requesting usage permission: $e');
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    try {
      await platform.invokeMethod('requestAccessibilityPermission');
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();
    } catch (e) {
      print('Error requesting accessibility permission: $e');
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      final apps = await platform.invokeMethod('getInstalledApps');
      setState(() {
        installedApps = List<Map<String, dynamic>>.from(
          apps.map((app) => {
                'appName': app['appName'],
                'packageName': app['packageName'],
              }),
        );
      });

      await _loadAppIcons();
    } catch (e) {
      print('Error loading installed apps: $e');
      _showErrorSnackbar('Failed to load installed apps');
    }
  }

  Future<void> _loadAppIcons() async {
    final batchSize = 15;
    for (int start = 0; start < installedApps.length; start += batchSize) {
      final end = (start + batchSize < installedApps.length)
          ? start + batchSize
          : installedApps.length;
      final batch = installedApps.sublist(start, end);
      for (final app in batch) {
        final packageName = app['packageName'] as String;
        try {
          final iconBytes = await platform.invokeMethod('getAppIcon', {
            'packageName': packageName,
          });
          if (iconBytes != null) {
            appIcons[packageName] = iconBytes as Uint8List;
          }
        } catch (e) {
          print('Error loading icon for $packageName: $e');
        }
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadBlockedApps() async {
    try {
      final blocked = await platform.invokeMethod('getBlockedApps');
      setState(() {
        blockedPackages = Set<String>.from(blocked);
      });
    } catch (e) {
      print('Error loading blocked apps: $e');
    }
  }

  String _getAppName(String packageName) {
    final match = installedApps.firstWhere(
      (app) => app['packageName'] == packageName,
      orElse: () => const {'appName': 'This app'},
    );
    return match['appName'] as String? ?? 'This app';
  }

  Future<void> _toggleAppBlock(String packageName, bool isBlocked) async {
    try {
      final success = await platform.invokeMethod('setAppBlockStatus', {
        'packageName': packageName,
        'isBlocked': isBlocked,
      });

      if (success) {
        setState(() {
          if (isBlocked) {
            blockedPackages.add(packageName);
          } else {
            blockedPackages.remove(packageName);
          }
        });

        if (isBlocked) {
          final appName = _getAppName(packageName);
          _showSuccessSnackbar('$appName is blocked');
        }

        if (isBlockingActive) {
          await _startBlockingService();
        }
      } else {
        _showErrorSnackbar('Failed to update app block status');
      }
    } catch (e) {
      print('Error toggling app block: $e');
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _startBlockingService() async {
    try {
      await platform.invokeMethod('startBlockingService');
      setState(() {
        isBlockingActive = true;
      });
      _showSuccessSnackbar('App blocking service started');
    } catch (e) {
      print('Error starting blocking service: $e');
      _showErrorSnackbar('Failed to start blocking service');
    }
  }

  Future<void> _stopBlockingService() async {
    try {
      await platform.invokeMethod('stopBlockingService');
      setState(() {
        isBlockingActive = false;
      });
      _showSuccessSnackbar('App blocking service stopped');
    } catch (e) {
      print('Error stopping blocking service: $e');
      _showErrorSnackbar('Failed to stop blocking service');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Map<String, dynamic>> get filteredApps {
    if (searchQuery.isEmpty) {
      return installedApps;
    }
    return installedApps.where((app) {
      final appName = app['appName'].toString().toLowerCase();
      final packageName = app['packageName'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return appName.contains(query) || packageName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).upHealHome;

    return UpHealScaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(tokens.screenPadding, 8, tokens.screenPadding, 0),
              child: Row(
                children: [
                  DrawerMenuButton(iconColor: tokens.primaryText),
                  SizedBox(width: tokens.space12),
                  Text(
                    'Block Apps',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: tokens.primaryText,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Padding(
                    padding: EdgeInsets.all(tokens.screenPadding),
                    child: ListView.builder(
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: SkeletonLoader.listItemSkeleton(),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (!hasUsagePermission || !hasAccessibilityPermission)
                        _buildPermissionsCard(),
                      _buildBlockingControlCard(),
                      _buildSearchBar(),
                      _buildBlockedAppsCount(),
                      Expanded(
                        child: _isRefreshing
                            ? const Center(child: CircularProgressIndicator())
                            : RefreshIndicator(
                                onRefresh: _refreshApps,
                                child: _buildAppsList(),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final tokens = Theme.of(context).upHealHome;

    return AppCard(
      padding: EdgeInsets.all(tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Color(0xFFF2B55D), size: 20),
              SizedBox(width: tokens.space8),
              Text(
                'Permissions Required',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.primaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space12),
          if (!hasUsagePermission)
            _buildPermissionItem(
              'Usage Stats Permission',
              'Required to monitor app usage',
              _requestUsagePermission,
            ),
          if (!hasAccessibilityPermission)
            _buildPermissionItem(
              'Accessibility Permission',
              'Required to block apps',
              _requestAccessibilityPermission,
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
      String title, String description, VoidCallback onPressed) {
    final tokens = Theme.of(context).upHealHome;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: tokens.primaryText,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tokens.faintText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.space12),
          _AccentGradientButton(
            onPressed: onPressed,
            child: const Text(
              'Grant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockingControlCard() {
    final tokens = Theme.of(context).upHealHome;
    final canActivate = hasUsagePermission && hasAccessibilityPermission;

    return AppCard(
      padding: EdgeInsets.all(tokens.space16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Blocking Service',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.primaryText,
                  ),
                ),
                SizedBox(height: tokens.space8 / 2),
                Text(
                  isBlockingActive
                      ? 'Service is running and monitoring apps'
                      : 'Service is stopped',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30, child: _AccentSwitch(
            value: isBlockingActive,
            onChanged: canActivate
                ? (value) {
                    if (value) {
                      _startBlockingService();
                    } else {
                      _stopBlockingService();
                    }
                  }
                : null,
          )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final tokens = Theme.of(context).upHealHome;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.screenPadding,
        vertical: tokens.space12,
      ),
      child: TextField(
        style: GoogleFonts.inter(
          color: tokens.primaryText,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: GoogleFonts.inter(
            color: tokens.faintText,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: tokens.secondaryText,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: tokens.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: tokens.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: tokens.secondaryText,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: tokens.cardFill,
          contentPadding: EdgeInsets.symmetric(
            horizontal: tokens.space16,
            vertical: tokens.space12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildBlockedAppsCount() {
    final tokens = Theme.of(context).upHealHome;

    return Padding(
      padding: EdgeInsets.fromLTRB(tokens.screenPadding, 0, tokens.screenPadding, tokens.space8),
      child: Row(
        children: [
          Text(
            '${blockedPackages.length} ${blockedPackages.length == 1 ? 'app' : 'apps'} blocked',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.secondaryText,
            ),
          ),
          if (blockedPackages.isNotEmpty) ...[
            const Spacer(),
            GestureDetector(
              onTap: _showClearAllDialog,
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF2B55D),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    final tokens = Theme.of(context).upHealHome;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.tileRadius),
          side: BorderSide(color: tokens.cardBorder),
        ),
        title: Text(
          'Clear All Blocked Apps?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: tokens.primaryText,
          ),
        ),
        content: Text(
          'This will unblock all apps. Are you sure you want to continue?',
          style: GoogleFonts.inter(
            color: tokens.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (final packageName in blockedPackages.toList()) {
                await _toggleAppBlock(packageName, false);
              }
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(
                color: const Color(0xFFF2B55D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsList() {
    final apps = filteredApps;
    final tokens = Theme.of(context).upHealHome;

    if (apps.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty
              ? 'No apps available'
              : 'No apps found matching "$searchQuery"',
          style: GoogleFonts.inter(
            color: tokens.faintText,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: tokens.screenPadding,
        right: tokens.screenPadding,
        bottom: tokens.screenPadding,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final packageName = app['packageName'] as String;
        final appName = app['appName'] as String;
        final isBlocked = blockedPackages.contains(packageName);

        return Container(
          padding: EdgeInsets.symmetric(vertical: tokens.space12),
          decoration: BoxDecoration(
            border: index < apps.length - 1
                ? Border(
                    bottom: BorderSide(color: tokens.dividerColor, width: 1),
                  )
                : null,
          ),
          child: Row(
            children: [
              _buildAppIcon(packageName, isBlocked, tokens),
              SizedBox(width: tokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.primaryText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: tokens.faintText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: tokens.space8),
              SizedBox(
                height: 26,
                child: _AccentSwitch(
                  value: isBlocked,
                  onChanged: (value) {
                    _toggleAppBlock(packageName, value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppIcon(String packageName, bool isBlocked, UpHealHomeTheme tokens) {
    final iconData = appIcons[packageName];

    if (iconData != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: tokens.cardFill,
          border: Border.all(color: tokens.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.memory(
            iconData,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(isBlocked, tokens);
            },
          ),
        ),
      );
    }

    return _buildFallbackIcon(isBlocked, tokens);
  }

  Widget _buildFallbackIcon(bool isBlocked, UpHealHomeTheme tokens) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Icon(
        isBlocked ? Icons.block : Icons.apps,
        color: isBlocked ? tokens.faintText : tokens.secondaryText,
        size: 20,
      ),
    );
  }
}

class _AccentGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AccentGradientButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: UpHealHomeTheme.sharedAccentGradient,
          borderRadius: BorderRadius.circular(999),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AccentSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _AccentSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFF8A6CF6),
      inactiveThumbColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF7D789C)
          : const Color(0xFF9A96B3),
      inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0x29FFFFFF)
          : const Color(0x1A141032),
    );
  }
}
