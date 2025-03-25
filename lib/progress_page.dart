import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  ProgressPageState createState() => ProgressPageState();
}

class ProgressPageState extends State<ProgressPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables for progress tracking
  double overallProgress = 0.0;
  List<ModuleProgress> modulesProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProgress();
  }

  Future<void> _fetchUserProgress() async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Handle unauthenticated user
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch user's progress from Firestore
      DocumentSnapshot userProgressDoc = await _firestore
          .collection('user_progress')
          .doc(currentUser.uid)
          .get();

      if (userProgressDoc.exists) {
        Map<String, dynamic> data =
            userProgressDoc.data() as Map<String, dynamic>;

        setState(() {
          // Parse overall progress
          overallProgress =
              (data['overall_progress'] as num?)?.toDouble() ?? 0.0;

          // Parse module progresses
          List<dynamic> modules = data['modules'] ?? [];
          modulesProgress = modules.map((moduleData) {
            return ModuleProgress(
              title: moduleData['title'] ?? '',
              progress: (moduleData['progress'] as num?)?.toDouble() ?? 0.0,
              color: _getColorForModule(moduleData['title']),
              icon: _getIconForModule(moduleData['title']),
              lastStudied: moduleData['last_studied'] != null
                  ? (moduleData['last_studied'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }).toList();

          _isLoading = false;
        });
      } else {
        // Create initial progress document if it doesn't exist
        await _initializeUserProgress(currentUser.uid);
      }
    } catch (e) {
      print('Error fetching user progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeUserProgress(String userId) async {
    // Default modules with initial progress
    List<Map<String, dynamic>> defaultModules = [
      {
        'title': 'Mathematics',
        'progress': 0.0,
        'last_studied': Timestamp.now(),
      },
      {
        'title': 'Science',
        'progress': 0.0,
        'last_studied': Timestamp.now(),
      },
      {
        'title': 'History',
        'progress': 0.0,
        'last_studied': Timestamp.now(),
      },
    ];

    await _firestore.collection('user_progress').doc(userId).set({
      'overall_progress': 0.0,
      'modules': defaultModules,
      'last_updated': Timestamp.now(),
    });

    // Refresh the progress after initialization
    _fetchUserProgress();
  }

  Future<void> _updateModuleProgress(
      String moduleName, double newProgress) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Update module progress in Firestore
      await _firestore.collection('user_progress').doc(currentUser.uid).update({
        'modules': FieldValue.arrayRemove([
          modulesProgress
              .firstWhere((module) => module.title == moduleName)
              .toFirestoreMap()
        ])
      });

      ModuleProgress updatedModule =
          modulesProgress.firstWhere((module) => module.title == moduleName)
            ..progress = newProgress
            ..lastStudied = DateTime.now();

      await _firestore.collection('user_progress').doc(currentUser.uid).update({
        'modules': FieldValue.arrayUnion([updatedModule.toFirestoreMap()]),
        'last_updated': Timestamp.now(),
        'overall_progress': _calculateOverallProgress(),
      });

      // Refresh local state
      _fetchUserProgress();
    } catch (e) {
      print('Error updating module progress: $e');
    }
  }

  double _calculateOverallProgress() {
    if (modulesProgress.isEmpty) return 0.0;
    return modulesProgress.map((m) => m.progress).reduce((a, b) => a + b) /
        modulesProgress.length;
  }

  Color _getColorForModule(String moduleName) {
    switch (moduleName) {
      case 'Mathematics':
        return Colors.blue;
      case 'Science':
        return Colors.green;
      case 'History':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForModule(String moduleName) {
    switch (moduleName) {
      case 'Mathematics':
        return Icons.calculate;
      case 'Science':
        return Icons.science;
      case 'History':
        return Icons.history_edu;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Progress')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Progress'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserProgress,
            tooltip: 'Refresh Progress',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Progress Section
            _buildOverallProgressSection(),

            const SizedBox(height: 32),

            // Module Progress Section
            _buildModuleProgressSection(),
          ],
        ),
      ),
    );
  }

  // Build methods

  Widget _buildModuleProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Module Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modulesProgress.length,
          itemBuilder: (context, index) {
            return _buildModuleProgressCard(modulesProgress[index]);
          },
        ),
      ],
    );
  }

  Widget _buildOverallProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 14.0,
          percent: overallProgress,
          backgroundColor: Colors.grey[300]!,
          progressColor: Colors.blue,
          center: Text(
            '${(overallProgress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Modify ModuleProgressCard to include an onTap handler for progress update
  Widget _buildModuleProgressCard(ModuleProgress moduleProgress) {
    return ModuleProgressCard(
      moduleProgress: moduleProgress,
      onTap: () => _showProgressUpdateDialog(moduleProgress),
    );
  }

  void _showProgressUpdateDialog(ModuleProgress module) {
    double currentProgress = module.progress;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Progress for ${module.title}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Current Progress: ${(currentProgress * 100).toStringAsFixed(0)}%'),
                  Slider(
                    value: currentProgress,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: '${(currentProgress * 100).toStringAsFixed(0)}%',
                    onChanged: (double value) {
                      setState(() {
                        currentProgress = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () {
                _updateModuleProgress(module.title, currentProgress);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Extend ModuleProgress with Firestore conversion methods
extension ModuleProgressFirestore on ModuleProgress {
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'progress': progress,
      'last_studied': Timestamp.fromDate(lastStudied),
    };
  }
}

class ModuleProgress {
  String title;
  double progress;
  Color color;
  IconData icon;
  DateTime lastStudied;

  ModuleProgress({
    required this.title,
    required this.progress,
    required this.color,
    required this.icon,
    required this.lastStudied,
  });
}

// ModuleProgressCard widget implementation
class ModuleProgressCard extends StatelessWidget {
  final ModuleProgress moduleProgress;
  final VoidCallback onTap;

  const ModuleProgressCard({
    Key? key,
    required this.moduleProgress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(moduleProgress.icon, color: moduleProgress.color),
        title: Text(moduleProgress.title),
        subtitle: Text(
          'Progress: ${(moduleProgress.progress * 100).toStringAsFixed(1)}%\n'
          'Last Studied: ${moduleProgress.lastStudied.toLocal()}',
        ),
        trailing: const Icon(Icons.edit),
        onTap: onTap,
      ),
    );
  }
}
