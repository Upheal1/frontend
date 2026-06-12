import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../data/community_models.dart';
import '../services/community_repository.dart';
import 'community_decor.dart';
import 'community_post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.initialPost});

  final CommunityPost initialPost;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  CommunityComment? _replyTo;
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _sendComment(CommunityRepository repo, UserModel user) async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    await repo.ensureSession(displayName: user.username);
    await repo.addComment(
      widget.initialPost.id,
      text,
      parentId: _replyTo?.id,
    );
    user.addXp(8);
    _composer.clear();
    setState(() => _replyTo = null);
  }

  List<CommunityComment> _roots(List<CommunityComment> all) {
    return all.where((c) => c.parentId == null).toList();
  }

  List<CommunityComment> _children(List<CommunityComment> all, String parentId) {
    return all.where((c) => c.parentId == parentId).toList();
  }

  Widget _commentTile(
    BuildContext context,
    List<CommunityComment> all,
    CommunityComment c,
    int depth,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final pad = 12.0 * depth;
    return Padding(
      padding: EdgeInsets.only(left: pad, bottom: 10),
      child: Ink(
        decoration: CommunityDecor.glassCard(context, radius: 14),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(
                    CommunityDecor.avatarFor(c.author.displayName),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.author.displayName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _replyTo = c),
                  child: Text('Reply', style: GoogleFonts.inter(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.body,
              style: GoogleFonts.inter(height: 1.35, fontSize: 14),
            ),
            ..._children(all, c.id).map(
              (ch) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _commentTile(context, all, ch, depth + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommunityRepository>();
    final user = context.watch<UserModel>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Thread', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommunityComment>>(
              stream: repo.watchComments(widget.initialPost.id),
              builder: (context, snap) {
                final comments = snap.data ?? const <CommunityComment>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    CommunityPostCard(
                      post: widget.initialPost,
                      onOpen: () {},
                      onLike: () => repo.toggleLike(widget.initialPost.id),
                      onShare: () => CommunityPostCard.sharePost(context, widget.initialPost),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Comments (${comments.length})',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Start the conversation — your voice matters.',
                          style: GoogleFonts.inter(color: scheme.onSurface.withOpacity(0.65)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ..._roots(comments).map((r) => _commentTile(context, comments, r, 0)),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              elevation: 8,
              color: scheme.surface.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_replyTo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(LucideIcons.cornerDownRight, size: 16, color: scheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Replying to ${_replyTo!.author.displayName}',
                                style: GoogleFonts.inter(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _replyTo = null),
                              icon: const Icon(LucideIcons.x, size: 18),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _composer,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Write something kind…',
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => _sendComment(repo, user),
                          icon: const Icon(LucideIcons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
