import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../models/journal_model.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';

const Color _jSage = Color(0xFF6B9E5E);
const Color _jTeal = Color(0xFF4ECDC4);
const Color _jGold = Color(0xFFD97706);

// ─────────────────────────── Mood data ────────────────────────────────────

class _Mood {
  final String label;
  final String emoji;
  final Color color;
  const _Mood(this.label, this.emoji, this.color);
}

const List<_Mood> _moods = [
  _Mood('Great',   '😄', Color(0xFFFFD60A)),
  _Mood('Good',    '😊', Color(0xFF6B9E5E)),
  _Mood('Calm',    '😌', Color(0xFF72B4D5)),
  _Mood('Neutral', '😐', Color(0xFF9CA3AF)),
  _Mood('Down',    '😔', Color(0xFF9B8EC4)),
  _Mood('Anxious', '😰', Color(0xFFFF8F6B)),
  _Mood('Sad',     '😢', Color(0xFF7BA7BC)),
];

// ─────────────────────────── Screen ───────────────────────────────────────

class JournalingQuestionsScreen extends StatefulWidget {
  const JournalingQuestionsScreen({super.key});

  @override
  State<JournalingQuestionsScreen> createState() =>
      _JournalingQuestionsScreenState();
}

class _JournalingQuestionsScreenState extends State<JournalingQuestionsScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  bool _isSubmitting = false;
  String? _selectedMood;

  final List<String> _questions = [
    'What are three things you\'re grateful for today?',
    'What was the highlight of your day?',
    'What challenge did you face today, and how did you handle it?',
    'How are you feeling right now?',
    'What would you like to improve or focus on tomorrow?',
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _questions.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  int _calculateXP() {
    int totalChars = _controllers.fold(0, (s, c) => s + c.text.trim().length);
    return 10 + (totalChars / 50).floor().clamp(0, 40);
  }

  Future<void> _submitJournal() async {
    final hasContent = _controllers.any((c) => c.text.trim().length >= 10);
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please answer at least one question (10+ characters)',
            style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select your current mood before saving',
            style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final filledPairs = _questions.asMap().entries
          .where((e) => _controllers[e.key].text.trim().isNotEmpty)
          .toList();

      final combinedText = filledPairs
          .map((e) => 'Q: ${e.value}\nA: ${_controllers[e.key].text.trim()}')
          .join('\n\n');

      final wc = combinedText.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime(now.year, now.month, now.day),
        entryText: combinedText,
        moodLabel: _selectedMood,
        timestamp: now,
        xpAwarded: _calculateXP(),
        sourceType: 'guided',
        wordCount: wc,
      );

      final journalModel = Provider.of<JournalModel>(context, listen: false);
      final success = await journalModel.saveEntry(entry);
      if (!success) throw Exception(journalModel.errorMessage ?? 'Failed to save');

      if (!mounted) return;
      await _showSuccessDialog(entry.xpAwarded ?? 10);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showSuccessDialog(int xp) async {
    final tokens = Theme.of(context).upHealHome;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.cardFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _jSage.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 16),
          Text('Journal Saved!',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
              color: tokens.primaryText)),
          const SizedBox(height: 8),
          Text('Great reflection. Keep it up!',
            style: GoogleFonts.inter(fontSize: 14, color: tokens.secondaryText),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _jGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _jGold.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('+$xp XP',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _jGold)),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _jSage, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).upHealHome;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: tokens.cardFill,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: tokens.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(children: [
          Text('Today\'s Reflection',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,
              color: tokens.primaryText)),
          Text(_todayDate(),
            style: GoogleFonts.inter(fontSize: 12, color: tokens.secondaryText)),
        ]),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitJournal,
            child: Text(
              _isSubmitting ? 'Saving…' : 'Done',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _isSubmitting ? Colors.grey : _jSage,
              ),
            ),
          ),
        ],
      ),
      body: UpHealPageBackground(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // ── Mood selector ──────────────────────────────────────────
          Text('How are you feeling?',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
              color: tokens.primaryText)),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _moods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final mood = _moods[i];
                final selected = _selectedMood == mood.label;
                return GestureDetector(
                  onTap: () => setState(() =>
                    _selectedMood = selected ? null : mood.label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? mood.color.withValues(alpha: 0.18)
                          : tokens.cardFill,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: selected ? mood.color : tokens.cardBorder,
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: selected ? [BoxShadow(
                        color: mood.color.withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )] : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(mood.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? mood.color : tokens.secondaryText,
                        )),
                    ]),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // ── Questions ──────────────────────────────────────────────
          ...List.generate(_questions.length, (i) => _buildQuestion(context, i, tokens)),

          const SizedBox(height: 24),

          // ── Save button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitJournal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _jSage,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _jSage.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(LucideIcons.save, size: 18),
                      const SizedBox(width: 8),
                      Text('Save Reflection',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, int i, UpHealHomeTheme tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: _jTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${i + 1}',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _jTeal)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_questions[i],
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: tokens.primaryText, height: 1.4)),
          ),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          maxLines: null,
          minLines: 3,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: tokens.primaryText,
            height: 1.6,
          ),
          textInputAction: i < _questions.length - 1
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: (_) {
            if (i < _questions.length - 1) _focusNodes[i + 1].requestFocus();
          },
          decoration: InputDecoration(
            hintText: 'Write your thoughts here…',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: tokens.secondaryText,
            ),
            filled: true,
            fillColor: tokens.cardFill,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _jTeal, width: 1.5),
            ),
          ),
        ),
      ]),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    const wdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
