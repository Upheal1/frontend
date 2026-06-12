import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../clinical_forms.dart';
import '../features/community/services/community_supabase.dart';
import '../navigation/navigation_helpers.dart';
import '../models/screen_time_model.dart';
import '../services/screen_time_service.dart';
import '../services/supabase_service.dart';
import '../services/upheal_api.dart';
import 'assessment_results_screen.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../constants/app_colors.dart';

class GadPhqFormScreen extends StatefulWidget {
  const GadPhqFormScreen({super.key});

  @override
  State<GadPhqFormScreen> createState() => _GadPhqFormScreenState();
}

class _GadPhqFormScreenState extends State<GadPhqFormScreen>
    with TickerProviderStateMixin {
  final Map<String, int> _answers = {};
  bool _submitting = false;

  late PageController _pageController;
  int _currentPage = 0;

  late AnimationController _progressAnim;
  late AnimationController _pageEnterController;
  late Animation<double> _pageEnterAnim;

  late List<_QuestionItem> _allQuestions;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _allQuestions = [
      ...gad7Form.questions.map((q) => _QuestionItem(
        form: gad7Form,
        question: q,
        prefix: 'gad7',
        sectionTitle: 'Anxiety Assessment',
        sectionColor: const Color(0xFF8B5CF6),
      )),
      ...phq9Form.questions.map((q) => _QuestionItem(
        form: phq9Form,
        question: q,
        prefix: 'phq9',
        sectionTitle: 'Depression Assessment',
        sectionColor: const Color(0xFF8B5CF6),
      )),
    ];

    _progressAnim = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pageEnterController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _pageEnterAnim = CurvedAnimation(
      parent: _pageEnterController,
      curve: Curves.easeOutCubic,
    );
    _pageEnterController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnim.dispose();
    _pageEnterController.dispose();
    super.dispose();
  }

  int get _total => _allQuestions.length;
  bool get _isComplete => _answers.length == _total;

  void _goNext() {
    if (_currentPage < _total - 1) {
      HapticFeedback.lightImpact();
      _pageEnterController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      _pageEnterController.forward();
    }
  }

  void _goPrevious() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageEnterController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      _pageEnterController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).upHealHome;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark, tokens),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _progressAnim.forward(from: 0);
                    _pageEnterController.reset();
                    _pageEnterController.forward();
                  },
                  itemCount: _total,
                  itemBuilder: (_, i) => _buildQuestionPage(i, isDark, tokens),
                ),
              ),
              _buildBottomNav(isDark, tokens),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, UpHealHomeTheme tokens) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => safeGoBack(context),
                icon: Icon(LucideIcons.arrowLeft, color: tokens.primaryText, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: tokens.trackColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const Spacer(),
              Text(
                'Question ${_currentPage + 1} of $_total',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.secondaryText),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => safeGoBack(context),
                icon: Icon(LucideIcons.x, color: tokens.secondaryText, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: tokens.trackColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _answers.length / _total),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: tokens.trackColor,
                valueColor: const AlwaysStoppedAnimation(AppColors.purple),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index, bool isDark, UpHealHomeTheme tokens) {
    final item = _allQuestions[index];
    final key = '${item.prefix}_q${item.question.id}';
    final selected = _answers[key];

    return FadeTransition(
      opacity: _pageEnterAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_pageEnterAnim),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: tokens.cardFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: tokens.cardBorder, width: 1),
                  boxShadow: tokens.cardShadow != null ? [tokens.cardShadow!] : null,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple.withValues(alpha: 0.12),
                            AppColors.purple.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Question ${item.question.id}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      item.question.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: tokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Over the last 2 weeks',
                      style: GoogleFonts.inter(fontSize: 14, color: tokens.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ...List.generate(item.form.optionsScale.length, (i) {
                final opt = item.form.optionsScale[i];
                final isSelected = selected == opt.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: i == item.form.optionsScale.length - 1 ? 100 : 12),
                  child: _buildOption(
                    label: opt.label,
                    value: opt.value,
                    isSelected: isSelected,
                    isDark: isDark,
                    tokens: tokens,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _answers[key] = opt.value);
                      if (!isSelected) {
                        Future.delayed(const Duration(milliseconds: 350), () {
                          if (mounted && _currentPage < _total - 1) _goNext();
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required int value,
    required bool isSelected,
    required bool isDark,
    required UpHealHomeTheme tokens,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: isSelected ? (Matrix4.diagonal3Values(1.02, 1.02, 1.0)) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.purple
              : tokens.cardFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : tokens.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : tokens.primaryText,
                ),
              ),
            ),
            if (isSelected)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                builder: (_, scale, __) => Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.check, size: 16, color: AppColors.purple),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, UpHealHomeTheme tokens) {
    final isLast = _currentPage == _total - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: tokens.pageBackground,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentPage > 0)
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _goPrevious,
                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.primaryText,
                    side: BorderSide(color: tokens.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              )
            else
              const SizedBox(width: 1),
            const Spacer(),
            if (!isLast)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _goNext,
                  icon: const Text(''),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.arrowRight, size: 18),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.purple.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              )
            else
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isComplete && !_submitting ? () => _onSubmitPressed(context) : null,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.sparkles, size: 18),
                  label: Text(
                    _submitting ? 'Analyzing...' : 'Get Results',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: tokens.trackColor,
                    disabledForegroundColor: tokens.faintText,
                    elevation: 4,
                    shadowColor: AppColors.purple.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- BACKEND METHODS (unchanged) ----

  Future<void> _onSubmitPressed(BuildContext context) async {
    if (!_isComplete) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _submitting = true;
    });

    final userId = SupabaseService.userId ?? 'anonymous';
    final screenTimeModel = context.read<ScreenTimeModel>();

    final rawUsage = await ScreenTimeService.getUltraAccurateUsageStats(period: 'daily');
    final totalMs = rawUsage.fold<int>(0, (sum, app) => sum + ((app['usageTime'] as int? ?? 0)));
    final freshMinutes = (totalMs ~/ 1000) ~/ 60;
    final totalMinutes = freshMinutes > 0
        ? freshMinutes
        : screenTimeModel.totalScreenTime.inMinutes;
    debugPrint('[ScreenTime] fresh=$freshMinutes min, model=${screenTimeModel.totalScreenTime.inMinutes} min, using=$totalMinutes min');

    int socialMs = 0, productivityMs = 0;
    for (final app in rawUsage) {
      final cat = (app['category'] as String? ?? '').toLowerCase();
      final ms = app['usageTime'] as int? ?? 0;
      if (cat == 'social') socialMs += ms;
      if (cat == 'productivity') productivityMs += ms;
    }
    final screenTimeData = <String, dynamic>{
      'totalMinutes': totalMinutes.toDouble(),
      'socialMinutes': ((socialMs ~/ 1000) ~/ 60).toDouble(),
      'productivityMinutes': ((productivityMs ~/ 1000) ~/ 60).toDouble(),
      'dailyUsage': rawUsage
          .where((app) => (app['usageTime'] as int? ?? 0) > 0)
          .map((app) => {
                'packageName': app['packageName'] ?? '',
                'usageTime': (((app['usageTime'] as int? ?? 0) ~/ 1000) ~/ 60),
                'category': (app['category'] as String? ?? 'unknown').toLowerCase(),
              })
          .toList(),
    };

    try {
      final Map<String, int> answers = Map.of(_answers);
      debugPrint('Submitting clinical answers: $answers');

      await _saveAssessmentLocally(answers: answers);

      Map<String, dynamic>? results;
      try {
        final api = UphealApi(baseUrl: uphealBaseUrl);

        debugPrint('[UphealApi] Testing server connectivity...');
        final connectivityTest = await api.testServerConnectivity();
        debugPrint('[UphealApi] Connectivity test: $connectivityTest');

        debugPrint('[UphealApi] Sending assess request...');
        debugPrint('[UphealApi] answers=${answers.length}');
        debugPrint('[UphealApi] userId=$userId');
        results = await api.assess(
          answers: answers,
          userId: userId,
          screenTimeData: screenTimeData,
        );
        debugPrint('RAG API response received: $results');
      } catch (e) {
        debugPrint('RAG API call failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.wifiOff, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Could not get AI recommendations',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      if (!mounted) return;

      if (results != null) {
        await _saveAssessmentResults(results);
        await _saveAssessmentToSupabase(
          answers: answers,
          screenTimeMinutes: totalMinutes,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AssessmentResultsScreen(results: results!),
          ),
        );
      } else {
        safeGoBack(context);
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('The operation is taking too long. Please try again.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e, st) {
      debugPrint('Error while saving assessment: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save assessment: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _saveAssessmentLocally({
    required Map<String, int> answers,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'clinical_answers_v1',
        jsonEncode(answers),
      );
      debugPrint('Clinical assessment answers saved locally.');
    } catch (e, st) {
      debugPrint('Failed to save assessment locally: $e\n$st');
    }
  }

  Future<void> _saveAssessmentToSupabase({
    required Map<String, int> answers,
    required int screenTimeMinutes,
    String locale = 'en',
  }) async {
    try {
      final userId = SupabaseService.userId;
      if (userId == null) return;

      final gad7Score = ['gad7_q1','gad7_q2','gad7_q3','gad7_q4','gad7_q5','gad7_q6','gad7_q7']
          .fold<int>(0, (sum, key) => sum + (answers[key] ?? 0));
      final phq9Score = ['phq9_q1','phq9_q2','phq9_q3','phq9_q4','phq9_q5','phq9_q6','phq9_q7','phq9_q8','phq9_q9']
          .fold<int>(0, (sum, key) => sum + (answers[key] ?? 0));

      await CommunitySupabase.clientOrNull
          ?.from('assessment_responses')
          .insert({
            'user_id': userId,
            'locale': locale,
            'form_payload': answers,
            'gad7_score': gad7Score,
            'phq9_score': phq9Score,
            'screen_time_minutes': screenTimeMinutes,
          });
      debugPrint('Assessment response saved to Supabase (gad7=$gad7Score, phq9=$phq9Score).');
    } catch (e, st) {
      debugPrint('Failed to save assessment to Supabase: $e\n$st');
    }
  }

  Future<void> _saveAssessmentResults(Map<String, dynamic> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = SupabaseService.userId;
      final key = userId != null
          ? 'assessment_results_$userId'
          : 'assessment_results_anonymous';

      final resultsWithTimestamp = {
        ...results,
        'saved_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString(key, jsonEncode(resultsWithTimestamp));
      debugPrint('Assessment results saved locally: $key');
    } catch (e, st) {
      debugPrint('Failed to save assessment results: $e\n$st');
    }
  }
}

class _QuestionItem {
  final ClinicalForm form;
  final ClinicalQuestion question;
  final String prefix;
  final String sectionTitle;
  final Color sectionColor;

  const _QuestionItem({
    required this.form,
    required this.question,
    required this.prefix,
    required this.sectionTitle,
    required this.sectionColor,
  });
}
