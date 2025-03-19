import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Ensure you have this package

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  // Sample data (replace with your actual data source)
  double overallProgress = 0.75; // Example: 75% overall progress
  List<ModuleProgress> modulesProgress = [
    ModuleProgress(title: 'Mathematics', progress: 0.85, color: Colors.blue),
    ModuleProgress(title: 'Science', progress: 0.60, color: Colors.green),
    ModuleProgress(title: 'History', progress: 0.92, color: Colors.orange),
    // ... more modules
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Progress
            const Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: overallProgress,
                center: Text(
                  '${(overallProgress * 100).toStringAsFixed(0)}%', // Show percentage
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                progressColor: Colors.blue,
                animation: true,
                animateFromLastPercent: true,
              ),
            ),
            const SizedBox(height: 32),

            // Module-wise Progress
            const Text(
              'Module Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scroll within column
              itemCount: modulesProgress.length,
              itemBuilder: (context, index) {
                return ModuleProgressCard(
                    moduleProgress: modulesProgress[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ModuleProgress {
  final String title;
  final double progress;
  final Color color;

  ModuleProgress({
    required this.title,
    required this.progress,
    required this.color,
  });
}

class ModuleProgressCard extends StatelessWidget {
  final ModuleProgress moduleProgress;

  const ModuleProgressCard({super.key, required this.moduleProgress});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: moduleProgress.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.book, // You can change this icon
                    color: moduleProgress.color,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  moduleProgress.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Linear Progress Indicator
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: moduleProgress.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(moduleProgress.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
