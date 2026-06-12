import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/community_repository.dart';
import '../state/community_notifiers.dart';
import 'feed_tab.dart';
import 'groups_tab.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => GroupsNotifier(ctx.read<CommunityRepository>()),
        ),
      ],
      child: const _CommunityPageShell(),
    );
  }
}

class _CommunityPageShell extends StatefulWidget {
  const _CommunityPageShell();

  @override
  State<_CommunityPageShell> createState() => _CommunityPageShellState();
}

class _CommunityPageShellState extends State<_CommunityPageShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GroupsNotifier>().connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(subtitleColor: subtitleColor),
                const SizedBox(height: 16),
                const TabBar(
                  tabs: [
                    Tab(text: 'Feed'),
                    Tab(text: 'Groups'),
                  ],
                ),
                const SizedBox(height: 12),
                const Expanded(
                  child: TabBarView(
                    children: [
                      FeedTab(),
                      GroupsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitleColor});

  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Community',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A safe space for your journey',
                style: TextStyle(color: subtitleColor),
              ),
            ],
          ),
        ),

      ],
    );
  }
}
