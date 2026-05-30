import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../clinical_forms.dart';
import '../models/auth_model.dart';
import '../services/supabase_auth_service.dart';
import '../services/upheal_api.dart';
import 'assessment_results_screen.dart';

/// Enhanced Combined GAD‑7 + PHQ‑9 questionnaire screen with modern UI.
class GadPhqFormScreen extends StatefulWidget {
  const GadPhqFormScreen({super.key});

  @override
  State<GadPhqFormScreen> createState() => _GadPhqFormScreenState();
}

class _GadPhqFormScreenState extends State<GadPhqFormScreen>
    with TickerProviderStateMixin {
  final Map<String, int> _answers = {};
  bool _submitting = false;
  
  // Page controller for swipe navigation
  late PageController _pageController;
  int _currentPage = 0;
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // All questions flattened for page view
  late List<_QuestionItem> _allQuestions;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Build flattened question list
    _allQuestions = [
      ...gad7Form.questions.map((q) => _QuestionItem(
        form: gad7Form,
        question: q,
        prefix: 'gad7',
        sectionTitle: 'Anxiety Assessment',
        sectionIcon: LucideIcons.brain,
        sectionColor: const Color(0xFFFF6B6B),
      )),
      ...phq9Form.questions.map((q) => _QuestionItem(
        form: phq9Form,
        question: q,
        prefix: 'phq9',
        sectionTitle: 'Depression Assessment',
        sectionIcon: LucideIcons.cloudRain,
        sectionColor: const Color(0xFF4ECDC4),
      )),
    ];
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  int get _totalQuestionCount => _allQuestions.length;
  bool get _isComplete => _answers.length == _totalQuestionCount;
  double get _progress => _answers.length / _totalQuestionCount;

  void _goToNextQuestion() {
    if (_currentPage < _totalQuestionCount - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToPreviousQuestion() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentItem = _allQuestions[_currentPage];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Progress
            _buildCustomAppBar(context, isDark, currentItem),
            
            // Question Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _totalQuestionCount,
                itemBuilder: (context, index) {
                  return _buildQuestionPage(context, index, isDark);
                },
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavigation(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, bool isDark, _QuestionItem currentItem) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with back button and section indicator
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  LucideIcons.x,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentItem.sectionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        currentItem.sectionIcon,
                        color: currentItem.sectionColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentItem.sectionTitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Question ${_currentPage + 1} of $_totalQuestionCount',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Completion badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isComplete
                      ? Colors.green.withOpacity(0.15)
                      : (isDark ? Colors.white10 : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_answers.length}/$_totalQuestionCount',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isComplete
                        ? Colors.green
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Animated Progress Bar
          _buildAnimatedProgressBar(isDark, currentItem),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressBar(bool isDark, _QuestionItem currentItem) {
    return Column(
      children: [
        // Segmented progress showing sections
        Row(
          children: [
            // GAD-7 section (7 questions)
            Expanded(
              flex: 7,
              child: _buildProgressSegment(
                isDark: isDark,
                color: const Color(0xFFFF6B6B),
                progress: _getGad7Progress(),
                label: 'GAD-7',
                isActive: _currentPage < 7,
              ),
            ),
            const SizedBox(width: 8),
            // PHQ-9 section (9 questions)
            Expanded(
              flex: 9,
              child: _buildProgressSegment(
                isDark: isDark,
                color: const Color(0xFF4ECDC4),
                progress: _getPhq9Progress(),
                label: 'PHQ-9',
                isActive: _currentPage >= 7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getGad7Progress() {
    int answered = 0;
    for (int i = 1; i <= 7; i++) {
      if (_answers.containsKey('gad7_q$i')) answered++;
    }
    return answered / 7;
  }

  double _getPhq9Progress() {
    int answered = 0;
    for (int i = 1; i <= 9; i++) {
      if (_answers.containsKey('phq9_q$i')) answered++;
    }
    return answered / 9;
  }

  Widget _buildProgressSegment({
    required bool isDark,
    required Color color,
    required double progress,
    required String label,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? color : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isActive ? color : color.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionPage(BuildContext context, int index, bool isDark) {
    final item = _allQuestions[index];
    final String answerKey = '${item.prefix}_q${item.question.id}';
    final int? selectedValue = _answers[answerKey];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F26) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: item.sectionColor.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.sectionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.sectionIcon,
                        size: 14,
                        color: item.sectionColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Q${item.question.id}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.sectionColor,
                        ),
                      ),
                      if (item.question.riskFlag) ...[
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.alertTriangle,
                          size: 14,
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Question text
                Text(
                  item.question.text,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Time frame reminder
                Text(
                  'Over the last 2 weeks',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Answer Options
          Text(
            'How often?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Answer buttons
          ...item.form.optionsScale.map((opt) {
            final bool selected = selectedValue == opt.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAnswerOption(
                context: context,
                option: opt,
                selected: selected,
                color: item.sectionColor,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _answers[answerKey] = opt.value;
                  });
                  // Auto-advance after short delay
                  if (!selected) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted && _currentPage < _totalQuestionCount - 1) {
                        _goToNextQuestion();
                      }
                    });
                  }
                },
              ),
            );
          }),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAnswerOption({
    required BuildContext context,
    required ClinicalOption option,
    required bool selected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(isDark ? 0.25 : 0.15)
                  : (isDark ? const Color(0xFF1A1F26) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? color
                    : (isDark ? Colors.white12 : Colors.grey[300]!),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Value indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? color
                        : (isDark ? Colors.white10 : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${option.value}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? color
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    LucideIcons.checkCircle,
                    color: color,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    final bool isLastPage = _currentPage >= _totalQuestionCount - 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentPage > 0)
            IconButton(
              onPressed: _goToPreviousQuestion,
              style: IconButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                padding: const EdgeInsets.all(12),
              ),
              icon: Icon(
                LucideIcons.arrowLeft,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 20,
              ),
            )
          else
            const SizedBox(width: 44),
          
          // On last page, show completion text instead of dots
          if (isLastPage)
            Expanded(
              child: Center(
                child: Text(
                  '${_answers.length}/$_totalQuestionCount completed',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isComplete ? Colors.green : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            )
          else ...[
            const Spacer(),
            // Page dots indicator (compact)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _totalQuestionCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: index == _currentPage ? 12 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _answers.containsKey(_getAnswerKey(index))
                        ? _allQuestions[index].sectionColor
                        : (index == _currentPage
                            ? _allQuestions[index].sectionColor.withOpacity(0.5)
                            : (isDark ? Colors.white24 : Colors.grey[300]!)),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
          
          // Next/Submit button
          if (!isLastPage)
            IconButton(
              onPressed: _goToNextQuestion,
              style: IconButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                padding: const EdgeInsets.all(12),
              ),
              icon: Icon(
                LucideIcons.arrowRight,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 20,
              ),
            )
          else
            ScaleTransition(
              scale: _isComplete ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: ElevatedButton.icon(
                onPressed: _isComplete && !_submitting
                    ? () => _onSubmitPressed(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.sparkles, size: 16),
                label: Text(
                  _submitting ? 'Analyzing...' : 'Get Results',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getAnswerKey(int index) {
    final item = _allQuestions[index];
    return '${item.prefix}_q${item.question.id}';
  }

  Future<void> _onSubmitPressed(BuildContext context) async {
    if (!_isComplete) return;
    HapticFeedback.mediumImpact();
    
    setState(() {
      _submitting = true;
    });

    try {
      final Map<String, int> answers = Map.of(_answers);
      debugPrint('Submitting clinical answers: $answers');

      await _saveAssessmentLocally(answers: answers);
      
      final authModel = Provider.of<AuthModel>(context, listen: false);
      final userId = authModel.userId ?? 'anonymous';
      final authToken = authModel.accessToken;

      Map<String, dynamic>? results;
      try {
        final api = UphealApi(baseUrl: uphealBaseUrl);
        results = await api.assess(
          answers: answers,
          userId: userId,
          authToken: authToken,
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
        // Save results for later viewing
        await _saveAssessmentResults(results);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AssessmentResultsScreen(results: results!),
          ),
        );
      } else {
        Navigator.of(context).pop();
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

  Future<void> _saveAssessmentResults(Map<String, dynamic> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = SupabaseAuthService().currentUserId;
      final key = userId != null 
          ? 'assessment_results_$userId' 
          : 'assessment_results_anonymous';
      
      // Add timestamp to results
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

/// Helper class to hold question with section metadata
class _QuestionItem {
  final ClinicalForm form;
  final ClinicalQuestion question;
  final String prefix;
  final String sectionTitle;
  final IconData sectionIcon;
  final Color sectionColor;

  const _QuestionItem({
    required this.form,
    required this.question,
    required this.prefix,
    required this.sectionTitle,
    required this.sectionIcon,
    required this.sectionColor,
  });
}
