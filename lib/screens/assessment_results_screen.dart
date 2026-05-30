import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/auth_model.dart';
import '../models/navigation_model.dart';

/// Enhanced screen to display clinical assessment results and RAG recommendations
class AssessmentResultsScreen extends StatefulWidget {
  final Map<String, dynamic> results;

  const AssessmentResultsScreen({
    super.key,
    required this.results,
  });

  @override
  State<AssessmentResultsScreen> createState() => _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _fadeController;
  late Animation<double> _gaugeAnimation;
  late Animation<double> _fadeAnimation;
  
  final Set<int> _expandedCards = {};
  bool _savedLocally = false;

  @override
  void initState() {
    super.initState();
    
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _gaugeAnimation = CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutCubic,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _gaugeController.forward();
    });
    
    // Mark assessment as completed
    _markAssessmentCompleted();
  }

  Future<void> _markAssessmentCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = context.read<AuthModel>().userId;
      if (userId != null) {
        await prefs.setBool('has_completed_assessment_$userId', true);
      }
    } catch (e) {
      debugPrint('Error marking assessment completed: $e');
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anxietyProb = (widget.results['anxiety_probability'] as num).toDouble();
    final depressionProb = (widget.results['depression_probability'] as num).toDouble();
    final severity = widget.results['severity'] as Map<String, dynamic>;
    final comorbidity = widget.results['comorbidity'] as bool;
    final recommendations = widget.results['rag_recommendations'] as List<dynamic>;
    final queryUsed = widget.results['query_used'] as String;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          try {
            // Navigate to home when back button is pressed and reset navigation index
            final navModel = context.read<NavigationModel>();
            navModel.setIndex(0);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RootNav()),
            );
          } catch (e) {
            debugPrint('Navigation error: $e');
            // Fallback: just navigate without setting index
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RootNav()),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB),
        body: CustomScrollView(
        slivers: [
          // Animated App Bar
          _buildSliverAppBar(context, severity, isDark),
          
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crisis Banner (if needed)
                    if (severity['anxiety'] == 'High' || severity['depression'] == 'High')
                      _buildCrisisSupportBanner(context),
                    
                    if (severity['anxiety'] == 'High' || severity['depression'] == 'High')
                      const SizedBox(height: 20),
                    
                    // Animated Gauge Cards
                    _buildGaugeSection(
                      context,
                      anxietyProb,
                      depressionProb,
                      severity,
                      comorbidity,
                      isDark,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Understanding Section
                    _buildUnderstandingSection(
                      context,
                      severity,
                      comorbidity,
                      isDark,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(context, severity, isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Action Plan
                    _buildActionPlan(context, severity, comorbidity, isDark),
                    
                    const SizedBox(height: 24),
                    
                    // AI Recommendations Header
                    _buildRecommendationsHeader(context, queryUsed, isDark),
                    
                    const SizedBox(height: 12),
                    
                    // Expandable Recommendation Cards
                    ...recommendations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rec = entry.value as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildExpandableRecommendationCard(
                          context,
                          rec,
                          index,
                          isDark,
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 16),
                    
                    // Disclaimer
                    _buildDisclaimer(context, isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Continue Button
                    _buildContinueButton(context, isDark),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> severity, bool isDark) {
    final anxietySev = severity['anxiety'] as String;
    final depressionSev = severity['depression'] as String;
    
    Color headerColor;
    String headerEmoji;
    String headerMessage;
    
    if (anxietySev == 'High' || depressionSev == 'High') {
      headerColor = Colors.red;
      headerEmoji = '💪';
      headerMessage = 'Support is Available';
    } else if (anxietySev == 'Moderate' || depressionSev == 'Moderate') {
      headerColor = Colors.orange;
      headerEmoji = '🌱';
      headerMessage = 'Room for Growth';
    } else {
      headerColor = Colors.green;
      headerEmoji = '✨';
      headerMessage = 'You\'re Doing Well';
    }

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1F26) : Colors.white,
      leading: IconButton(
        icon: Icon(
          LucideIcons.home,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () {
          try {
            // Navigate to home and reset navigation index
            final navModel = context.read<NavigationModel>();
            navModel.setIndex(0);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RootNav()),
            );
          } catch (e) {
            debugPrint('Navigation error: $e');
            // Fallback: just navigate without setting index
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RootNav()),
            );
          }
        },
        tooltip: 'Go to Home',
      ),
      actions: [
        IconButton(
          icon: Icon(
            _savedLocally ? LucideIcons.checkCircle : LucideIcons.bookmark,
            color: _savedLocally ? Colors.green : (isDark ? Colors.white70 : Colors.black54),
          ),
          onPressed: _saveResults,
          tooltip: 'Save Results',
        ),
        IconButton(
          icon: Icon(
            LucideIcons.share2,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: _shareResults,
          tooltip: 'Share',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      headerColor.withOpacity(0.3),
                      const Color(0xFF1A1F26),
                    ]
                  : [
                      headerColor.withOpacity(0.15),
                      Colors.white,
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        headerEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerMessage,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your personalized assessment results',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGaugeSection(
    BuildContext context,
    double anxietyProb,
    double depressionProb,
    Map<String, dynamic> severity,
    bool comorbidity,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnimatedGaugeCard(
                context,
                'Anxiety',
                anxietyProb,
                severity['anxiety'] as String,
                const Color(0xFFFF6B6B),
                LucideIcons.brain,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnimatedGaugeCard(
                context,
                'Depression',
                depressionProb,
                severity['depression'] as String,
                const Color(0xFF4ECDC4),
                LucideIcons.cloudRain,
                isDark,
              ),
            ),
          ],
        ),
        
        if (comorbidity) ...[
          const SizedBox(height: 12),
          _buildComorbidityBanner(context, isDark),
        ],
      ],
    );
  }

  Widget _buildAnimatedGaugeCard(
    BuildContext context,
    String label,
    double probability,
    String severityText,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _gaugeAnimation,
      builder: (context, child) {
        final animatedProb = probability * _gaugeAnimation.value;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F26) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      severityText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Circular Gauge
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _GaugePainter(
                    progress: animatedProb,
                    color: color,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[200]!,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(animatedProb * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildComorbidityBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(isDark ? 0.3 : 0.1),
            Colors.indigo.withOpacity(isDark ? 0.3 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.alertTriangle,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comorbidity Detected',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.purple[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Both anxiety and depression indicators are present. This is common and treatable.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisSupportBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.heartPulse,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Need Immediate Support?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If you\'re in crisis or having thoughts of self-harm, please reach out immediately. Help is available 24/7.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchPhone('988'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.phone, size: 18),
                  label: Text(
                    'Call 988',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchSMS('988'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.messageCircle, size: 18),
                  label: Text(
                    'Text 988',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnderstandingSection(
    BuildContext context,
    Map<String, dynamic> severity,
    bool comorbidity,
    bool isDark,
  ) {
    final anxietySev = severity['anxiety'] as String;
    final depressionSev = severity['depression'] as String;
    
    String title;
    String description;
    IconData icon;
    Color color;
    
    if (anxietySev == 'High' || depressionSev == 'High') {
      title = 'Understanding Your Results';
      description = 'Your assessment indicates elevated symptoms that may benefit from professional support. '
          'Remember, these feelings are common and highly treatable. Many people with similar scores '
          'see significant improvement with proper care.';
      icon = LucideIcons.heartHandshake;
      color = Colors.red;
    } else if (anxietySev == 'Moderate' || depressionSev == 'Moderate') {
      title = 'What This Means';
      description = 'Your results show moderate symptoms. This is a good time to take action with self-care '
          'strategies and possibly professional guidance. Early intervention can make a significant difference.';
      icon = LucideIcons.lightbulb;
      color = Colors.orange;
    } else {
      title = 'Great News!';
      description = 'Your assessment shows low symptom levels. Continue practicing self-care and maintaining '
          'healthy habits. This app can help you track your wellness and stay on top of your mental health.';
      icon = LucideIcons.sparkles;
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic> severity, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: LucideIcons.calendarPlus,
                label: 'Find Therapist',
                color: const Color(0xFF6366F1),
                isDark: isDark,
                onTap: () => _launchUrl('https://www.psychologytoday.com/us/therapists'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: LucideIcons.bookOpen,
                label: 'Learn CBT',
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => _launchUrl('https://www.apa.org/ptsd-guideline/patients-and-families/cognitive-behavioral'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: LucideIcons.users,
                label: 'Support Groups',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => _launchUrl('https://www.nami.org/Support-Education/Support-Groups'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPlan(
    BuildContext context,
    Map<String, dynamic> severity,
    bool comorbidity,
    bool isDark,
  ) {
    final steps = _getActionSteps(severity, comorbidity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.listChecks, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Action Plan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${steps.length} personalized steps',
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
          
          const SizedBox(height: 20),
          
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _buildActionStepItem(
              context,
              index + 1,
              step,
              isDark,
              isLast: index == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionStepItem(
    BuildContext context,
    int number,
    Map<String, dynamic> step,
    bool isDark, {
    bool isLast = false,
  }) {
    final priority = step['priority'] as String;
    final color = priority == 'high'
        ? Colors.red
        : priority == 'medium'
            ? Colors.orange
            : Colors.blue;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.only(top: 8),
                  color: color.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      step['icon'] as IconData,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        step['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step['description'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsHeader(BuildContext context, String queryUsed, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.indigo],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI-Powered Recommendations',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Based on clinical literature',
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
      ],
    );
  }

  Widget _buildExpandableRecommendationCard(
    BuildContext context,
    Map<String, dynamic> rec,
    int index,
    bool isDark,
  ) {
    final isExpanded = _expandedCards.contains(index);
    final source = rec['source'] as String;
    final section = rec['section'] as String;
    final content = rec['content'] as String;
    final similarity = (rec['similarity'] as num).toDouble();
    final pages = rec['pages'] as String;

    Color relevanceColor;
    String relevanceLabel;
    if (similarity >= 80) {
      relevanceColor = Colors.green;
      relevanceLabel = 'Highly Relevant';
    } else if (similarity >= 70) {
      relevanceColor = Colors.orange;
      relevanceLabel = 'Relevant';
    } else {
      relevanceColor = Colors.grey;
      relevanceLabel = 'Related';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? relevanceColor.withOpacity(0.5)
              : (isDark ? Colors.white10 : Colors.grey[200]!),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: relevanceColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCards.remove(index);
              } else {
                _expandedCards.add(index);
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.indigo],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            source,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: relevanceColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${similarity.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: relevanceColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        LucideIcons.chevronDown,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          content,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.6,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.bookOpen,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pages: $pages',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: relevanceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              relevanceLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: relevanceColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            color: Colors.amber[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These recommendations are educational and not a substitute for professional mental health care. Please consult with a licensed professional for diagnosis and treatment.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.amber[200] : Colors.amber[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          try {
            // Navigate to home and reset navigation index
            final navModel = context.read<NavigationModel>();
            navModel.setIndex(0);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RootNav()),
            );
          } catch (e) {
            debugPrint('Navigation error: $e');
            // Fallback: just navigate without setting index
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RootNav()),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue to UpHeal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, size: 20),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActionSteps(
    Map<String, dynamic> severity,
    bool comorbidity,
  ) {
    final anxietySev = severity['anxiety'] as String;
    final depressionSev = severity['depression'] as String;
    
    List<Map<String, dynamic>> steps = [];
    
    if (anxietySev == 'High' || depressionSev == 'High' || comorbidity) {
      steps.add({
        'title': 'Schedule a Professional Consultation',
        'description': 'Connect with a licensed therapist or psychiatrist for proper evaluation.',
        'icon': LucideIcons.stethoscope,
        'priority': 'high',
      });
    }
    
    if (anxietySev != 'Low' || depressionSev != 'Low') {
      steps.add({
        'title': 'Explore Cognitive Behavioral Therapy',
        'description': 'CBT is highly effective for both anxiety and depression.',
        'icon': LucideIcons.brain,
        'priority': anxietySev == 'High' || depressionSev == 'High' ? 'high' : 'medium',
      });
    }
    
    steps.add({
      'title': 'Establish Healthy Routines',
      'description': 'Regular sleep, balanced nutrition, and daily structure.',
      'icon': LucideIcons.calendar,
      'priority': 'medium',
    });
    
    steps.add({
      'title': 'Exercise Regularly',
      'description': '30 minutes of moderate activity most days.',
      'icon': LucideIcons.dumbbell,
      'priority': 'medium',
    });
    
    steps.add({
      'title': 'Track Your Progress',
      'description': 'Use this app to monitor symptoms and celebrate wins.',
      'icon': LucideIcons.trendingUp,
      'priority': 'low',
    });
    
    return steps;
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _saveResults() async {
    try {
      HapticFeedback.lightImpact();
      // Results are already saved locally in the form screen
      setState(() {
        _savedLocally = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Results saved to your profile',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving results: $e');
    }
  }

  void _shareResults() async {
    final anxietyProb = (widget.results['anxiety_probability'] as num).toDouble();
    final depressionProb = (widget.results['depression_probability'] as num).toDouble();
    final severity = widget.results['severity'] as Map<String, dynamic>;
    
    final shareText = '''
UpHeal Assessment Summary

Anxiety Level: ${severity['anxiety']} (${(anxietyProb * 100).toInt()}%)
Depression Level: ${severity['depression']} (${(depressionProb * 100).toInt()}%)

This assessment was completed using MindQuest app.
For professional help, please consult a licensed mental health professional.
''';

    await Share.share(shareText, subject: 'My UpHeal Assessment');
  }
}

/// Custom painter for circular gauge
class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
