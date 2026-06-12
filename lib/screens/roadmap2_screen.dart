import 'package:flutter/material.dart';

import '../navigation/navigation_helpers.dart';
import '../widgets/roadmap_demo_video.dart';

class Roadmap2Screen extends StatelessWidget {
  const Roadmap2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RoadmapDemoVideo(),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Colors.black26,
                      Colors.transparent,
                      Colors.black54,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => safeGoBack(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
