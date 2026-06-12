import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../data/community_models.dart';
import '../services/community_repository.dart';
import 'community_decor.dart';

class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key});

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final _body = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  final Set<String> _tags = {};

  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final list = await _picker.pickMultiImage(imageQuality: 82);
    if (list.isEmpty) return;
    setState(() {
      _images
        ..clear()
        ..addAll(list.take(4));
    });
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    final repo = context.read<CommunityRepository>();
    final user = context.read<UserModel>();
    final text = _body.text.trim();
    if (text.isEmpty && _images.isEmpty) return;

    setState(() => _busy = true);
    try {
      await repo.ensureSession(displayName: user.username);
      await repo.createPost(
        body: text.isEmpty ? ' ' : text,
        tags: _tags.toList(),
        images: _images,
      );
      user.addXp(15);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: GoogleFonts.inter()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
            gradient: CommunityDecor.calmBackdrop(context)),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFF4F5F7),
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'New post',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Share button
                    GestureDetector(
                      onTap: _busy ? null : _submit,
                      child: AnimatedOpacity(
                        opacity: _busy ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: CommunityDecor.fabGradient,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: _busy
                                ? []
                                : [
                                    BoxShadow(
                                      color: CommunityDecor.lavender
                                          .withOpacity(0.38),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Share',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    // Author row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                CommunityDecor.lavender,
                                CommunityDecor.mint
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Image.network(
                              CommunityDecor.avatarFor(user.username),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username.isNotEmpty
                                    ? user.username
                                    : 'You',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sharing with community',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Prompt
                    Text(
                      'What shifted for you today?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Body text field
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFFAFAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: TextField(
                        controller: _body,
                        minLines: 6,
                        maxLines: 14,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Progress, gratitude, a question…',
                          hintStyle: GoogleFonts.inter(
                            color: isDark
                                ? Colors.white30
                                : const Color(0xFFBBBCC7),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tags
                    Text(
                      'Tags',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCommunityTagPresets.map((t) {
                        final on = _tags.contains(t);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (on) {
                                _tags.remove(t);
                              } else {
                                _tags.add(t);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: on
                                  ? const LinearGradient(colors: [
                                      CommunityDecor.lavender,
                                      CommunityDecor.mint
                                    ])
                                  : null,
                              color: on
                                  ? null
                                  : isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : const Color(0xFFF4F5F7),
                              borderRadius: BorderRadius.circular(99),
                              border: on
                                  ? null
                                  : Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : const Color(0xFFD1D5DB)),
                            ),
                            child: Text(
                              t,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: on
                                    ? Colors.white
                                    : isDark
                                        ? Colors.white70
                                        : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Photo picker
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    CommunityDecor.lavender,
                                    CommunityDecor.mint
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.imagePlus,
                                  size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _images.isEmpty
                                  ? 'Add photos'
                                  : '${_images.length} photo${_images.length > 1 ? 's' : ''} selected',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Image preview grid
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _images.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (_, i) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(_images[i].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _images.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black54,
                                    ),
                                    child: const Icon(LucideIcons.x,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
