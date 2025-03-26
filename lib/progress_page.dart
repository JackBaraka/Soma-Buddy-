import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:async';
import 'dart:developer';

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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProgress();
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

      setState(() {
        overallProgress = (data['overall_progress'] as num?)?.toDouble() ?? 0.0;

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
      await _fetchUserProgress();
    } catch (e) {
      _handleUnexpectedError(e);
    }
  }

  // Other existing methods remain the same...

  // Removed unused method _calculateOverallProgress

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

  Color _getColorForModule(String moduleName) {
    switch (moduleName) {
      case 'Mathematics':
        return Colors.blue;
      case 'Science':
        return Colors.green;
      case 'History':
        return Colors.brown;
      default:
        return Colors.grey;
    }
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
      body: RefreshIndicator(
        onRefresh: _fetchUserProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing progress section methods
              _buildOverallProgressSection(),
              const SizedBox(height: 32),
              _buildModuleProgressSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Existing helper methods...

  Widget _buildModuleProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Module Progress',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modulesProgress.length,
          itemBuilder: (context, index) {
            final module = modulesProgress[index];
            return Card(
              child: ListTile(
                leading: Icon(module.icon, color: module.color),
                title: Text(module.title),
                subtitle: LinearPercentIndicator(
                  lineHeight: 14.0,
                  percent: module.progress,
                  backgroundColor: Colors.grey[300]!,
                  progressColor: module.color,
                  center: Text(
                    '${(module.progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                trailing: Text(
                  'Last studied: ${module.lastStudied.toLocal()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
}

// Extension and other classes remain the same as in previous implementation
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
