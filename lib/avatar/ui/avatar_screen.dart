import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../navigation/navigation_helpers.dart';
import '../services/avatar_provider.dart';
import 'avatar_widget.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  static const List<String> _uploadedAvatars = [
    'assets/avatar/baby_boy/baby_batman.png',
    'assets/avatar/baby_girl/baby_rubbenzel.png',
    'assets/avatar/baby_girl/baby_yasmine.png',
    'assets/avatar/baby_boy/baby_hulk.png'
  ];

  String? _selectedAvatar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedAvatar ??= context.read<AvatarProvider>().selectedAvatarAsset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = context.read<AvatarProvider>().config;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => safeGoBack(context),
        ),
        title: Text(
          'Choose Avatar',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.42,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.purple.withOpacity(0.08),
                              border: Border.all(
                                color: AppColors.purple.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                          ),
                          AvatarWidget(
                            config: config,
                            mood: 'happy',
                            size: 200,
                            avatarAssetPath: _selectedAvatar,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _uploadedAvatars.length,
                    itemBuilder: (context, index) {
                      final asset = _uploadedAvatars[index];
                      final selected = _selectedAvatar == asset;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = asset),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.purple.withOpacity(0.06)
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.purple
                                      : Colors.grey.withOpacity(0.2),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 92,
                                    child: Image.asset(
                                      asset,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.image_not_supported,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _labelFromAsset(asset),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? AppColors.purple
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Positioned(
                                right: 6,
                                top: 6,
                                child: _SelectedBadge(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              color: theme.scaffoldBackgroundColor,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveAvatarSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save avatar',
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFromAsset(String assetPath) {
    final fileName = assetPath.split('/').last.replaceAll('.png', '');
    return fileName
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _saveAvatarSelection() {
    final selected = _selectedAvatar ?? _uploadedAvatars.first;
    context.read<AvatarProvider>().selectUploadedAvatar(selected);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar saved')),
    );
    safeGoBack(context);
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.purple,
      ),
      child: const Icon(
        Icons.check,
        size: 10,
        color: Colors.white,
      ),
    );
  }
}
