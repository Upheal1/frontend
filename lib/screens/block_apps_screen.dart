import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/drawer_menu_button.dart';

class BlockAppsScreen extends StatefulWidget {
  const BlockAppsScreen({Key? key}) : super(key: key);

  @override
  State<BlockAppsScreen> createState() => _BlockAppsScreenState();
}

class _BlockAppsScreenState extends State<BlockAppsScreen> {
  static const platform = MethodChannel('com.appguard.native_calls');

  // ── In-memory cache ──────────────────────────────────────────────────
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
      // Restore from cache — no native call needed
      setState(() {
        installedApps = _cachedInstalledApps!;
        appIcons = Map<String, Uint8List?>.from(_cachedAppIcons);
        isLoading = false;
      });
    } else {
      // First load — skeleton is shown while native call runs
      await _loadInstalledApps();
    }

    await _loadBlockedApps();

    // If cache was just populated, turn off loading
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
      
      // Load app icons (awaited so cache captures them)
      await _loadAppIcons();
    } catch (e) {
      print('Error loading installed apps: $e');
      _showErrorSnackbar('Failed to load installed apps');
    }
  }

  Future<void> _loadAppIcons() async {
    // Load icons in batches of 15 to reduce rebuilds
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
      // Batch-update after each group to limit setState calls
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

        // If blocking is active, update the service
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1B1B1B) : Colors.grey[50];
    final primaryColor = isDark ? AppColors.purple : AppColors.teal;
    
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // Custom AppBar-like header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const DrawerMenuButton(iconColor: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Block Apps',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // Removed local navigation drawer to rely on the root drawer

  Widget _buildPermissionsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.orange[50];
    final borderColor = isDark ? Colors.orange.withOpacity(0.3) : Colors.orange.withOpacity(0.2);
    
    return Card(
      margin: const EdgeInsets.all(16),
      color: cardColor,
      elevation: isDark ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Permissions Required',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildPermissionItem(
      String title, String description, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.purple : AppColors.teal;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Grant'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockingControlCard() {
    final canActivate = hasUsagePermission && hasAccessibilityPermission;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final primaryColor = isDark ? AppColors.purple : AppColors.teal;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      elevation: isDark ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Blocking Service',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBlockingActive
                        ? 'Service is running and monitoring apps'
                        : 'Service is stopped',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
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
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF2D2D2D) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.purple : AppColors.teal,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: fillColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.grey[700];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${blockedPackages.length} ${blockedPackages.length == 1 ? 'app' : 'apps'} blocked',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (blockedPackages.isNotEmpty) ...[
            const Spacer(),
            TextButton(
              onPressed: () {
                _showClearAllDialog();
              },
              child: const Text('Clear All'),
            ),
          ],
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Blocked Apps?'),
        content: const Text(
            'This will unblock all apps. Are you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Unblock all apps
              for (final packageName in blockedPackages.toList()) {
                await _toggleAppBlock(packageName, false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsList() {
    final apps = filteredApps;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;

    if (apps.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty
              ? 'No apps available'
              : 'No apps found matching "$searchQuery"',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final packageName = app['packageName'] as String;
        final appName = app['appName'] as String;
        final isBlocked = blockedPackages.contains(packageName);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: cardColor,
          elevation: isDark ? 2 : 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey[200]!,
            ),
          ),
          child: ListTile(
            leading: _buildAppIcon(packageName, isBlocked),
            title: Text(
              appName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              packageName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
            trailing: Switch(
              value: isBlocked,
              onChanged: (value) {
                _toggleAppBlock(packageName, value);
              },
              activeColor: Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppIcon(String packageName, bool isBlocked) {
    final iconData = appIcons[packageName];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isBlocked 
        ? Colors.red.withOpacity(0.5) 
        : (isDark ? Colors.white24 : Colors.grey.withOpacity(0.3));
    
    if (iconData != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            iconData,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(isBlocked);
            },
          ),
        ),
      );
    }
    
    return _buildFallbackIcon(isBlocked);
  }

  Widget _buildFallbackIcon(bool isBlocked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.purple : AppColors.teal;
    final backgroundColor = isBlocked 
        ? Colors.red.withOpacity(0.1) 
        : primaryColor.withOpacity(0.1);
    final borderColor = isBlocked 
        ? Colors.red.withOpacity(0.5) 
        : (isDark ? primaryColor.withOpacity(0.5) : primaryColor.withOpacity(0.3));
    final iconColor = isBlocked ? Colors.red : primaryColor;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Icon(
        isBlocked ? Icons.block : Icons.apps,
        color: iconColor,
        size: 24,
      ),
    );
  }
}
