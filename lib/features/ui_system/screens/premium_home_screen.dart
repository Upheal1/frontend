import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/premium_bottom_nav.dart';
import '../widgets/premium_side_menu.dart';
import '../widgets/premium_components.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> {
  int _currentIndex = 0;
  bool _isMenuOpen = false;
  int _selectedMenuIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    _JournalTab(),
    _FocusTab(),
    _ProgressTab(),
    _ProfileTab(),
  ];

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedMenuIndex = index;
      if (index < 5) {
        _currentIndex = index;
      }
    });
  }

  void _openQuickActions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _QuickActionsSheet(
        onStartFocus: () {
          Navigator.pop(context);
        },
        onAddJournal: () {
          Navigator.pop(context);
        },
        onAICheckIn: () {
          Navigator.pop(context);
        },
        onTrackMood: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          PremiumSideMenu(
            isOpen: _isMenuOpen,
            onClose: _toggleMenu,
            selectedIndex: _selectedMenuIndex,
            onItemSelected: _onMenuItemSelected,
            userName: 'John Doe',
            userEmail: 'john@example.com',
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  LucideIcons.menu,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.3),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  LucideIcons.bell,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.3),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: PremiumBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavItem(icon: LucideIcons.home, label: 'Home'),
                BottomNavItem(icon: LucideIcons.bookOpen, label: 'Journal'),
                BottomNavItem(icon: LucideIcons.target, label: 'Focus'),
                BottomNavItem(icon: LucideIcons.barChart3, label: 'Progress'),
                BottomNavItem(icon: LucideIcons.user, label: 'Profile'),
              ],
              onFABTap: _openQuickActions,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  final VoidCallback? onStartFocus;
  final VoidCallback? onAddJournal;
  final VoidCallback? onAICheckIn;
  final VoidCallback? onTrackMood;

  const _QuickActionsSheet({
    this.onStartFocus,
    this.onAddJournal,
    this.onAICheckIn,
    this.onTrackMood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: LucideIcons.target,
                        label: 'Focus',
                        color: const Color(0xFF8B5CF6),
                        onTap: onStartFocus,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        icon: LucideIcons.pencil,
                        label: 'Journal',
                        color: const Color(0xFF06B6D4),
                        onTap: onAddJournal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: LucideIcons.messagesSquare,
                        label: 'AI Chat',
                        color: const Color(0xFF45D9A8),
                        onTap: onAICheckIn,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        icon: LucideIcons.smile,
                        label: 'Mood',
                        color: const Color(0xFFF97316),
                        onTap: onTrackMood,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ).animate().slideY(begin: 0.5, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            const Text(
              'Ready to grow? 🌱',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildDailyQuote(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.flame,
            value: '7',
            label: 'Day Streak',
            color: const Color(0xFFF97316),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.star,
            value: '1,240',
            label: 'XP',
            color: const Color(0xFFFFD700),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.trophy,
            value: '12',
            label: 'Badges',
            color: const Color(0xFF8B5CF6),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.2),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Continue Your Journey',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Morning Meditation',
          subtitle: '10 min • Mindfulness',
          icon: LucideIcons.mountain,
          color: const Color(0xFF06B6D4),
          progress: 0.7,
        ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideX(begin: 0.1),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Focus Session',
          subtitle: '25 min • Deep Work',
          icon: LucideIcons.target,
          color: const Color(0xFF8B5CF6),
          progress: 0.0,
        ).animate().fadeIn(duration: 400.ms, delay: 700.ms).slideX(begin: 0.1),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(20),
      showGlow: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuote() {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: const Color(0xFF45D9A8).withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.lightbulb,
                color: Color(0xFF45D9A8),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Daily Inspiration',
                style: TextStyle(
                  color: Color(0xFF45D9A8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"The journey of a thousand miles begins with a single step."',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— Lao Tzu',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 800.ms).slideY(begin: 0.2);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalTab extends StatelessWidget {
  const _JournalTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Journal Tab',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class _FocusTab extends StatelessWidget {
  const _FocusTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Focus Tab',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Progress Tab',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Tab',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}