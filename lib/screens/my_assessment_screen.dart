import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/supabase_auth_service.dart';
import 'gad_phq_form_screen.dart';
import 'assessment_results_screen.dart';
import '../widgets/drawer_menu_button.dart';
import '../constants/app_colors.dart';

/// Screen to view past assessment results or start a new assessment
class MyAssessmentScreen extends StatefulWidget {
  const MyAssessmentScreen({super.key});

  @override
  State<MyAssessmentScreen> createState() => _MyAssessmentScreenState();
}

class _MyAssessmentScreenState extends State<MyAssessmentScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _savedResults;
  late AnimationController _fadeController;
  late AnimationController _gaugeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _gaugeAnimation = CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutCubic,
    );
    _loadSavedResults();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _gaugeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = SupabaseAuthService().currentUserId;
      final key = userId != null
          ? 'assessment_results_$userId'
          : 'assessment_results_anonymous';

      final savedJson = prefs.getString(key);
      if (savedJson != null) {
        final results = jsonDecode(savedJson) as Map<String, dynamic>;
        // Navigate to full results screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AssessmentResultsScreen(results: results),
            ),
          );
        }
        return;
      } else {
        setState(() {
          _savedResults = null;
          _loading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Error loading saved results: $e');
      setState(() {
        _savedResults = null;
        _loading = false;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldState = Scaffold.maybeOf(context);
    final hasDrawer = scaffoldState?.hasDrawer ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB),
      appBar: AppBar(
            leading: hasDrawer
                ? DrawerMenuButton(
                    iconColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textPrimary,
                  )
                : IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
        title: Text(
          'My Results',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_savedResults != null)
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: () => _navigateToAssessment(),
              tooltip: 'Take New Assessment',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _savedResults == null
                  ? _buildNoResultsView(isDark)
                  : _buildResultsView(isDark),
            ),
    );
  }

  Widget _buildNoResultsView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Container
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                      : [const Color(0xFF818CF8), const Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.clipboardList,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Assessment Yet',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Take the GAD-7 and PHQ-9 clinical assessment to understand your mental wellness and get personalized recommendations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            // Feature Cards
            _buildFeatureCard(
              icon: LucideIcons.brain,
              title: 'AI-Powered Analysis',
              subtitle: 'Get insights powered by advanced AI',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: LucideIcons.target,
              title: 'Personalized Tips',
              subtitle: 'Receive recommendations for your needs',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: LucideIcons.lock,
              title: 'Private & Secure',
              subtitle: 'Your data stays on your device',
              isDark: isDark,
            ),
            const SizedBox(height: 40),
            // Start Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _navigateToAssessment(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.play, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Start Assessment',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(bool isDark) {
    final anxietyProb =
        (_savedResults!['anxiety_probability'] as num?)?.toDouble() ?? 0.0;
    final depressionProb =
        (_savedResults!['depression_probability'] as num?)?.toDouble() ?? 0.0;
    final severity =
        _savedResults!['severity'] as Map<String, dynamic>? ?? {};
    final savedAt = _savedResults!['saved_at'] as String?;
    final recommendations =
        _savedResults!['rag_recommendations'] as List<dynamic>? ?? [];

    String formattedDate = 'Unknown date';
    if (savedAt != null) {
      try {
        final date = DateTime.parse(savedAt);
        formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Date
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.calendar,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Assessment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Score Gauges
          Row(
            children: [
              Expanded(
                child: _buildScoreGauge(
                  label: 'Anxiety',
                  value: anxietyProb,
                  severity: severity['anxiety'] as String? ?? 'Unknown',
                  color: _getAnxietyColor(severity['anxiety'] as String?),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreGauge(
                  label: 'Depression',
                  value: depressionProb,
                  severity: severity['depression'] as String? ?? 'Unknown',
                  color: _getDepressionColor(severity['depression'] as String?),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Severity Summary
          _buildSeveritySummary(severity, isDark),
          const SizedBox(height: 20),

          // Recommendations Section
          if (recommendations.isNotEmpty) ...[
            Text(
              'Your Recommendations',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...recommendations.take(3).map((rec) {
              final recMap = rec as Map<String, dynamic>;
              return _buildRecommendationCard(recMap, isDark);
            }),
            const SizedBox(height: 20),
          ],

          // Retake Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _navigateToAssessment(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.refreshCw, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Take New Assessment',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScoreGauge({
    required String label,
    required double value,
    required String severity,
    required Color color,
    required bool isDark,
  }) {
    return AnimatedBuilder(
      animation: _gaugeAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _GaugePainter(
                        value: value * _gaugeAnimation.value,
                        color: color,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(value * 100 * _gaugeAnimation.value).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severity,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeveritySummary(Map<String, dynamic> severity, bool isDark) {
    final anxietySev = severity['anxiety'] as String? ?? 'Unknown';
    final depressionSev = severity['depression'] as String? ?? 'Unknown';

    String overallMessage;
    IconData overallIcon;
    Color overallColor;

    if (anxietySev == 'High' || depressionSev == 'High') {
      overallMessage =
          'Your scores indicate you may benefit from speaking with a professional.';
      overallIcon = LucideIcons.alertTriangle;
      overallColor = const Color(0xFFEF4444);
    } else if (anxietySev == 'Moderate' || depressionSev == 'Moderate') {
      overallMessage =
          'Your scores suggest some areas to focus on. Consider self-care practices.';
      overallIcon = LucideIcons.info;
      overallColor = const Color(0xFFF59E0B);
    } else {
      overallMessage =
          'Great news! Your scores indicate healthy mental wellness. Keep it up!';
      overallIcon = LucideIcons.checkCircle;
      overallColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: overallColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: overallColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: overallColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(overallIcon, color: overallColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              overallMessage,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
      Map<String, dynamic> rec, bool isDark) {
    final title = rec['title'] as String? ?? 'Recommendation';
    final description = rec['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.lightbulb,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _getAnxietyColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getDepressionColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  void _navigateToAssessment() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GadPhqFormScreen(),
      ),
    );
  }
}

/// Circular gauge painter for score visualization
class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const strokeWidth = 10.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5 * value.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
