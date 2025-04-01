// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:developer';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  ProgressPageState createState() => ProgressPageState();
}

class ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  // State variables for progress tracking
  double overallProgress = 0.0;
  List<ModuleProgress> modulesProgress = [];
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _lastUpdated;
  int _streakDays = 0;
  int _completedActivities = 0;
  bool _showDetailedView = false;
  List<ProgressHistoryEntry> _progressHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check authentication
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'Please log in to view your progress',
        );
      }

      // Fetch user's progress from Firestore
      DocumentSnapshot userProgressDoc = await _firestore
          .collection('user_progress')
          .doc(currentUser.uid)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your internet.');
        },
      );

      // Check if document exists
      if (!userProgressDoc.exists) {
        await _initializeUserProgress(currentUser.uid);
        return;
      }

      // Parse progress data
      Map<String, dynamic> data =
          userProgressDoc.data() as Map<String, dynamic>;

      // Fetch progress history
      QuerySnapshot historySnapshot = await _firestore
          .collection('user_progress')
          .doc(currentUser.uid)
          .collection('history')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      setState(() {
        overallProgress = (data['overall_progress'] as num?)?.toDouble() ?? 0.0;
        _streakDays = (data['streak_days'] as num?)?.toInt() ?? 0;
        _completedActivities =
            (data['completed_activities'] as num?)?.toInt() ?? 0;
        _lastUpdated = data['last_updated'] != null
            ? (data['last_updated'] as Timestamp).toDate()
            : null;

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
            completedLessons:
                (moduleData['completed_lessons'] as num?)?.toInt() ?? 0,
            totalLessons: (moduleData['total_lessons'] as num?)?.toInt() ?? 10,
          );
        }).toList();

        // Parse progress history
        _progressHistory = historySnapshot.docs.map((doc) {
          Map<String, dynamic> historyData = doc.data() as Map<String, dynamic>;
          return ProgressHistoryEntry(
            date: (historyData['date'] as Timestamp).toDate(),
            overallProgress:
                (historyData['overall_progress'] as num).toDouble(),
            activitiesCompleted:
                (historyData['activities_completed'] as num).toInt(),
          );
        }).toList();

        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      _handleFirebaseError(e);
    } on TimeoutException catch (e) {
      _handleTimeoutError(e);
    } catch (e) {
      _handleUnexpectedError(e);
    }
  }

  void _handleFirebaseError(FirebaseException e) {
    setState(() {
      _isLoading = false;
      _errorMessage = _getFirebaseErrorMessage(e);
    });

    _showErrorSnackBar(_errorMessage);
  }

  void _handleTimeoutError(TimeoutException e) {
    setState(() {
      _isLoading = false;
      _errorMessage =
          e.message ?? 'Connection timed out. Please check your internet.';
    });

    _showErrorSnackBar(_errorMessage);
  }

  void _handleUnexpectedError(Object e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
    });

    _showErrorSnackBar(_errorMessage);
    log('Unexpected error: $e', name: 'ProgressPage');
  }

  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to access this data.';
      case 'not-found':
        return 'Progress data not found.';
      case 'unauthenticated':
        return 'Please log in to view your progress.';
      case 'unavailable':
        return 'Firestore service is currently unavailable.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _initializeUserProgress(String userId) async {
    try {
      List<Map<String, dynamic>> defaultModules = [
        {
          'title': 'Mathematics',
          'progress': 0.0,
          'last_studied': Timestamp.now(),
          'completed_lessons': 0,
          'total_lessons': 10,
        },
        {
          'title': 'Science',
          'progress': 0.0,
          'last_studied': Timestamp.now(),
          'completed_lessons': 0,
          'total_lessons': 12,
        },
        {
          'title': 'History',
          'progress': 0.0,
          'last_studied': Timestamp.now(),
          'completed_lessons': 0,
          'total_lessons': 8,
        },
        {
          'title': 'Languages',
          'progress': 0.0,
          'last_studied': Timestamp.now(),
          'completed_lessons': 0,
          'total_lessons': 15,
        },
      ];

      // Create main document
      await _firestore.collection('user_progress').doc(userId).set({
        'overall_progress': 0.0,
        'modules': defaultModules,
        'last_updated': Timestamp.now(),
        'streak_days': 0,
        'completed_activities': 0,
      });

      // Initialize history with first entry
      await _firestore
          .collection('user_progress')
          .doc(userId)
          .collection('history')
          .add({
        'date': Timestamp.now(),
        'overall_progress': 0.0,
        'activities_completed': 0,
      });

      // Refresh the progress after initialization
      await _fetchUserProgress();
    } catch (e) {
      _handleUnexpectedError(e);
    }
  }

  Future<void> _simulateProgressUpdate() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Update a random module progress
      final random = DateTime.now().millisecond % modulesProgress.length;
      ModuleProgress module = modulesProgress[random];

      // Increase progress by 10% but cap at 100%
      double newProgress = (module.progress + 0.1).clamp(0.0, 1.0);
      int newCompletedLessons = ((newProgress * module.totalLessons).round())
          .clamp(0, module.totalLessons);

      // Update the module in our local list
      setState(() {
        module.progress = newProgress;
        module.completedLessons = newCompletedLessons;
        module.lastStudied = DateTime.now();

        // Recalculate overall progress
        double total = 0.0;
        for (var mod in modulesProgress) {
          total += mod.progress;
        }
        overallProgress = (total / modulesProgress.length).clamp(0.0, 1.0);
        _completedActivities += 1;
      });

      // Update modules list for Firestore
      List<Map<String, dynamic>> modulesForFirestore =
          modulesProgress.map((module) => module.toFirestoreMap()).toList();

      // Update main document
      await _firestore.collection('user_progress').doc(currentUser.uid).update({
        'overall_progress': overallProgress,
        'modules': modulesForFirestore,
        'last_updated': Timestamp.now(),
        'completed_activities': _completedActivities,
        'streak_days': _streakDays + 1, // Increment streak
      });

      // Add new history entry
      await _firestore
          .collection('user_progress')
          .doc(currentUser.uid)
          .collection('history')
          .add({
        'date': Timestamp.now(),
        'overall_progress': overallProgress,
        'activities_completed': _completedActivities,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress updated for ${module.title}!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      await _fetchUserProgress();
    } catch (e) {
      _handleUnexpectedError(e);
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
      case 'Languages':
        return Icons.language;
      case 'Technology':
        return Icons.computer;
      default:
        return Icons.book;
    }
  }

  Color _getColorForModule(String moduleName) {
    switch (moduleName) {
      case 'Mathematics':
        return Colors.blue;
      case 'Science':
        return Colors.green;
      case 'History':
        return Colors.brown;
      case 'Languages':
        return Colors.purple;
      case 'Technology':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y - h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading and error states
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Progress')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if exists
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Progress')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchUserProgress,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Normal progress view
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Overview Tab
            RefreshIndicator(
              onRefresh: _fetchUserProgress,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildOverallProgressSection(),
                    const SizedBox(height: 24),
                    _buildModuleProgressSection(),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _simulateProgressUpdate,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Simulate Progress Update'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // History & Achievements Tab
            RefreshIndicator(
              onRefresh: _fetchUserProgress,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressHistorySection(),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '$_streakDays',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Day Streak', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '$_completedActivities',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Completed', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.trending_up, color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${(overallProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Overall', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Module Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: Icon(_showDetailedView ? Icons.list : Icons.grid_view),
              label: Text(_showDetailedView ? 'List View' : 'Grid View'),
              onPressed: () {
                setState(() {
                  _showDetailedView = !_showDetailedView;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _showDetailedView ? _buildDetailedModuleList() : _buildModuleGrid(),
      ],
    );
  }

  Widget _buildDetailedModuleList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modulesProgress.length,
      itemBuilder: (context, index) {
        final module = modulesProgress[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: module.color.withOpacity(0.2),
              child: Icon(module.icon, color: module.color),
            ),
            title: Text(module.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: LinearPercentIndicator(
              lineHeight: 10.0,
              percent: module.progress,
              backgroundColor: Colors.grey[300]!,
              progressColor: module.color,
              padding: const EdgeInsets.only(top: 8, right: 16),
              barRadius: const Radius.circular(5),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completed: ${module.completedLessons}/${module.totalLessons} lessons',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${(module.progress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: module.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last studied: ${_formatDateTime(module.lastStudied)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Continue'),
                          onPressed: () {
                            // Future implementation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Opening ${module.title} module...'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: modulesProgress.length,
      itemBuilder: (context, index) {
        final module = modulesProgress[index];
        return Card(
          elevation: 3,
          child: InkWell(
            onTap: () {
              // Future implementation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening ${module.title} module...'),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: module.color.withOpacity(0.2),
                    child: Icon(module.icon, color: module.color, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  CircularPercentIndicator(
                    radius: 35.0,
                    lineWidth: 5.0,
                    percent: module.progress,
                    center: Text(
                      '${(module.progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14),
                    ),
                    progressColor: module.color,
                    backgroundColor: Colors.grey[300]!,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverallProgressSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 15.0,
              percent: overallProgress,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(overallProgress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const Text('Completed'),
                ],
              ),
              progressColor: Colors.blue,
              backgroundColor: Colors.grey[300]!,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1200,
            ),
            const SizedBox(height: 16),
            if (_lastUpdated != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Last updated: ${_formatDateTime(_lastUpdated!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHistorySection() {
    if (_progressHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No progress history available yet'),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _progressHistory.length.clamp(0, 7),
              itemBuilder: (context, index) {
                final entry = _progressHistory[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: const Icon(Icons.history, color: Colors.blue),
                  ),
                  title: Text(DateFormat('MMM d, y').format(entry.date)),
                  subtitle: Text(
                      'Activities completed: ${entry.activitiesCompleted}'),
                  trailing: Text(
                    '${(entry.overallProgress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final List<Map<String, dynamic>> achievements = [
      {
        'title': 'First Steps',
        'description': 'Complete your first learning module',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'unlocked': overallProgress > 0.1,
      },
      {
        'title': 'Persistence',
        'description': 'Maintain a 5-day streak',
        'icon': Icons.whatshot,
        'color': Colors.orange,
        'unlocked': _streakDays >= 5,
      },
      {
        'title': 'Half Way There',
        'description': 'Reach 50% overall progress',
        'icon': Icons.star,
        'color': Colors.purple,
        'unlocked': overallProgress >= 0.5,
      },
      {
        'title': 'Dedicated Learner',
        'description': 'Complete 10 learning activities',
        'icon': Icons.school,
        'color': Colors.teal,
        'unlocked': _completedActivities >= 10,
      },
    ];

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: achievement['unlocked']
                        ? achievement['color']
                        : Colors.grey[300],
                    child: Icon(
                      achievement['icon'],
                      color: achievement['unlocked']
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    achievement['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: achievement['unlocked'] ? null : Colors.grey[600],
                    ),
                  ),
                  subtitle: Text(achievement['description']),
                  trailing: achievement['unlocked']
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.lock, color: Colors.grey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension ModuleProgressFirestore on ModuleProgress {
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'progress': progress,
      'last_studied': Timestamp.fromDate(lastStudied),
      'completed_lessons': completedLessons,
      'total_lessons': totalLessons,
    };
  }
}

class ModuleProgress {
  String title;
  double progress;
  Color color;
  IconData icon;
  DateTime lastStudied;
  int completedLessons;
  int totalLessons;

  ModuleProgress({
    required this.title,
    required this.progress,
    required this.color,
    required this.icon,
    required this.lastStudied,
    this.completedLessons = 0,
    this.totalLessons = 10,
  });
}

class ProgressHistoryEntry {
  final DateTime date;
  final double overallProgress;
  final int activitiesCompleted;

  ProgressHistoryEntry({
    required this.date,
    required this.overallProgress,
    required this.activitiesCompleted,
  });
}
