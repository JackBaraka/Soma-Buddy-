import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContentPage extends StatefulWidget {
  const ContentPage.named({super.key, this.onModuleStatusChanged});

  @override
  ContentPageState createState() => ContentPageState();
  final Function(LearningContent, ContentModule, bool)? onModuleStatusChanged;

  const ContentPage({super.key, this.onModuleStatusChanged});
}

class ContentPageState extends State<ContentPage> {
  int _selectedTabIndex = 0;
  String _selectedFaculty = 'Medicine'; // Default faculty
  List<LearningContent> _savedContents = [];
  bool _isLoading = true;
  List<LearningContent> _currentContents = [];

  // Available faculties
  final List<String> _faculties = [
    'Medicine',
    'Technology',
    'Music',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses(_selectedFaculty);
    _fetchSavedCourses();
  }

  // Fetch courses based on selected faculty
  Future<void> _fetchCourses(String faculty) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('faculty', isEqualTo: faculty)
          .get();

      List<LearningContent> courses = [];

      for (var doc in coursesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Fetch modules for this course
        final QuerySnapshot modulesSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .doc(doc.id)
            .collection('modules')
            .get();

        List<ContentModule> modules = modulesSnapshot.docs.map((moduleDoc) {
          final moduleData = moduleDoc.data() as Map<String, dynamic>;
          return ContentModule(
            id: moduleDoc.id,
            title: moduleData['title'] ?? '',
            duration: moduleData['duration'] ?? '',
            isCompleted: moduleData['isCompleted'] ?? false,
            pointsEarned: moduleData['pointsEarned'] ?? 0,
          );
        }).toList();

        // Create course object
        courses.add(
          LearningContent(
            id: doc.id,
            title: data['title'] ?? '',
            category: data['category'] ?? '',
            faculty: data['faculty'] ?? '',
            description: data['description'] ?? '',
            progress: data['progress']?.toDouble() ?? 0.0,
            difficulty: _parseDifficulty(data['difficulty']),
            imageUrl: data['imageUrl'] ?? '',
            modules: modules,
            learningPathways: List<String>.from(data['learningPathways'] ?? []),
            instructorName: data['instructorName'] ?? 'Faculty Staff',
          ),
        );
      }

      setState(() {
        _currentContents = courses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch saved courses for the current user
  Future<void> _fetchSavedCourses() async {
    try {
      // Assume we have user authentication and current user ID
      String userId =
          'current_user_id'; // Replace with actual user ID from auth

      final QuerySnapshot savedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedCourses')
          .get();

      List<String> savedCourseIds =
          savedSnapshot.docs.map((doc) => doc.id).toList();

      List<LearningContent> savedCourses = [];
      for (String courseId in savedCourseIds) {
        final DocumentSnapshot courseDoc = await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .get();

        if (courseDoc.exists) {
          final data = courseDoc.data() as Map<String, dynamic>;

          // Fetch modules for this course
          final QuerySnapshot modulesSnapshot = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .get();

          List<ContentModule> modules = modulesSnapshot.docs.map((moduleDoc) {
            final moduleData = moduleDoc.data() as Map<String, dynamic>;
            return ContentModule(
              id: moduleDoc.id,
              title: moduleData['title'] ?? '',
              duration: moduleData['duration'] ?? '',
              isCompleted: moduleData['isCompleted'] ?? false,
              pointsEarned: moduleData['pointsEarned'] ?? 0,
            );
          }).toList();

          savedCourses.add(
            LearningContent(
              id: courseDoc.id,
              title: data['title'] ?? '',
              category: data['category'] ?? '',
              faculty: data['faculty'] ?? '',
              description: data['description'] ?? '',
              progress: data['progress']?.toDouble() ?? 0.0,
              difficulty: _parseDifficulty(data['difficulty']),
              imageUrl: data['imageUrl'] ?? '',
              modules: modules,
              learningPathways:
                  List<String>.from(data['learningPathways'] ?? []),
              instructorName: data['instructorName'] ?? 'Faculty Staff',
            ),
          );
        }
      }

      setState(() {
        _savedContents = savedCourses;
      });
    } catch (e) {
      debugPrint('Error fetching saved courses: $e');
    }
  }

  // Add a course to saved courses
  Future<void> _saveCourse(LearningContent content) async {
    try {
      String userId =
          'current_user_id'; // Replace with actual user ID from auth

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedCourses')
          .doc(content.id)
          .set({
        'savedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        if (!_savedContents.any((c) => c.id == content.id)) {
          _savedContents.add(content);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course saved successfully')),
      );
    } catch (e) {
      print('Error saving course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save course')),
      );
    }
  }

  // Update module completion status
  Future<void> _updateModuleStatus(
      LearningContent course, ContentModule module, bool isCompleted) async {
    try {
      String userId =
          'current_user_id'; // Replace with actual user ID from auth

      // Update module status in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('courseProgress')
          .doc(course.id)
          .collection('modules')
          .doc(module.id)
          .set({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));

      // Calculate new progress for the course
      int completedModules = course.modules.where((m) => m.isCompleted).length;
      if (isCompleted && !module.isCompleted) completedModules++;
      if (!isCompleted && module.isCompleted) completedModules--;

      double newProgress = course.modules.isNotEmpty
          ? completedModules / course.modules.length
          : 0.0;

      // Update course progress in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('courseProgress')
          .doc(course.id)
          .set({
        'progress': newProgress,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local state
      setState(() {
        module.isCompleted = isCompleted;
        module.pointsEarned = isCompleted ? 25 : 0; // Example points

        // Update progress in current courses
        for (var c in _currentContents) {
          if (c.id == course.id) {
            c.progress = newProgress;
            break;
          }
        }

        // Update progress in saved courses
        for (var c in _savedContents) {
          if (c.id == course.id) {
            c.progress = newProgress;
            break;
          }
        }
      });
    } catch (e) {
      print('Error updating module status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update progress')),
      );
    }
  }

  Difficulty _parseDifficulty(String? difficultyStr) {
    switch (difficultyStr?.toLowerCase()) {
      case 'beginner':
        return Difficulty.beginner;
      case 'intermediate':
        return Difficulty.intermediate;
      case 'advanced':
        return Difficulty.advanced;
      default:
        return Difficulty.beginner;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('University Learning Center'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Implement notification handling
            },
          ),
          IconButton(
            icon: Icon(Icons.content_paste),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContentPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to profile page
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFacultySelector(),
          _buildCategoryTabs(),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildLearningContents()
                : _selectedTabIndex == 1
                    ? _buildRecommendedContents()
                    : _buildSavedContents(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFacultySelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      color: Colors.indigo.shade50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _faculties.map((faculty) {
            bool isSelected = _selectedFaculty == faculty;
            return Padding(
              padding: EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(faculty),
                selected: isSelected,
                selectedColor: Colors.indigo.shade200,
                backgroundColor: Colors.grey.shade200,
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      _selectedFaculty = faculty;
                    });
                    _fetchCourses(faculty);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabButton('My Courses', 0),
          _buildTabButton('Recommended', 1),
          _buildTabButton('Saved', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return TextButton(
      onPressed: () => setState(() => _selectedTabIndex = index),
      style: TextButton.styleFrom(
        backgroundColor: _selectedTabIndex == index
            ? Colors.indigo.shade400
            : Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: _selectedTabIndex == index ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLearningContents() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_currentContents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No courses found for $_selectedFaculty',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _currentContents.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final content = _currentContents[index];
        return _buildContentCard(content);
      },
    );
  }

  Widget _buildContentCard(LearningContent content) {
    bool isSaved = _savedContents.any((c) => c.id == content.id);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image
          content.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: content.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: Icon(Icons.school, size: 50),
                  ),
                )
              : Container(
                  height: 150,
                  color: Colors.indigo.shade100,
                  child: Center(
                    child: Icon(Icons.school, size: 50, color: Colors.indigo),
                  ),
                ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDifficultyChip(content.difficulty),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.indigo : Colors.grey,
                      ),
                      onPressed: () => _saveCourse(content),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  content.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content.description,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        content.instructorName.isNotEmpty
                            ? content.instructorName[0]
                            : 'I',
                        style: TextStyle(
                            fontSize: 12, color: Colors.indigo.shade700),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prof. ${content.instructorName}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Progress: ${(content.progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Spacer(),
                              Text(
                                '${content.modules.where((m) => m.isCompleted).length}/${content.modules.length} modules',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: content.progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              content.progress > 0.7
                                  ? Colors.green
                                  : Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContentDetailPage(
                          content: content,
                          onModuleStatusChanged: _updateModuleStatus,
                        ),
                      ),
                    );
                  },
                  child: Text('Continue Learning'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(Difficulty difficulty) {
    String label;
    Color color;

    switch (difficulty) {
      case Difficulty.beginner:
        label = 'Beginner';
        color = Colors.green;
        break;
      case Difficulty.intermediate:
        label = 'Intermediate';
        color = Colors.orange;
        break;
      case Difficulty.advanced:
        label = 'Advanced';
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRecommendedContents() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/recommendation.svg',
            height: 200,
          ),
          SizedBox(height: 20),
          Text(
            'Personalized Course Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Based on your academic profile and interests',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Implement navigation to interests selection
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Update Interests'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedContents() {
    if (_savedContents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No saved courses yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bookmark courses to access them quickly',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _savedContents.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final content = _savedContents[index];
        return _buildContentCard(content);
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      onTap: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      selectedItemColor: Colors.indigo,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.recommend),
          label: 'Recommended',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
      ],
    );
  }

  CachedNetworkImage(
      {required String imageUrl,
      required int height,
      required double width,
      required BoxFit fit,
      required Container Function(dynamic context, dynamic url) placeholder,
      required Container Function(dynamic context, dynamic url, dynamic error)
          errorWidget}) {}
}

class ContentDetailPage extends StatelessWidget {
  final LearningContent content;
  final Function(LearningContent, ContentModule, bool) onModuleStatusChanged;

  const ContentDetailPage({
    super.key,
    required this.content,
    required this.onModuleStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(content.title),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            if (content.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: content.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Icon(Icons.school, size: 50),
                ),
              ),

            // Course details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    content.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        content.faculty,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.category, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(content.category),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Prof. ${content.instructorName}'),
                    ],
                  ),

                  // Learning pathways
                  if (content.learningPathways.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Learning Pathways',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: content.learningPathways.map((pathway) {
                        return Chip(
                          label: Text(pathway),
                          backgroundColor: Colors.indigo.shade50,
                        );
                      }).toList(),
                    ),
                  ],

                  // Progress
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Course Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(content.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: content.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      content.progress > 0.7 ? Colors.green : Colors.indigo,
                    ),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),

                  // Modules
                  SizedBox(height: 24),
                  Text(
                    'Course Modules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Module list
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: content.modules.length,
              itemBuilder: (context, index) {
                final module = content.modules[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      module.title,
                      style: TextStyle(
                        fontWeight: module.isCompleted
                            ? FontWeight.normal
                            : FontWeight.bold,
                        decoration: module.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: module.isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('Duration: ${module.duration}'),
                            if (module.isCompleted) ...[
                              SizedBox(width: 16),
                              Icon(Icons.stars, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text('Points: ${module.pointsEarned}'),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Checkbox(
                      value: module.isCompleted,
                      activeColor: Colors.indigo,
                      onChanged: (bool? value) {
                        if (value != null) {
                          onModuleStatusChanged(content, module, value);
                        }
                      },
                    ),
                    onTap: () {
                      // Navigate to module content
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModuleContentPage(
                            content: content,
                            module: module,
                            onModuleStatusChanged: onModuleStatusChanged,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class ModuleContentPage extends StatelessWidget {
  final LearningContent content;
  final ContentModule module;
  final Function(LearningContent, ContentModule, bool) onModuleStatusChanged;

  const ModuleContentPage({
    super.key,
    required this.content,
    required this.module,
    required this.onModuleStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(module.title),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('courses')
            .doc(content.id)
            .collection('modules')
            .doc(module.id)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading module content'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Module content not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> contentSections = data['contentSections'] ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module header
                Text(
                  module.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Duration: ${module.duration}'),
                  ],
                ),
                SizedBox(height: 16),

                // Module content sections
                ...contentSections.map((section) {
                  final sectionType = section['type'] as String? ?? 'text';
                  final sectionTitle = section['title'] as String? ?? '';
                  final sectionContent = section['content'] as String? ?? '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sectionTitle.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          sectionTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                      if (sectionType == 'text')
                        Text(
                          sectionContent,
                          style: TextStyle(fontSize: 16),
                        )
                      else if (sectionType == 'image')
                        CachedNetworkImage(
                          imageUrl: sectionContent,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )
                      else if (sectionType == 'video')
                        Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.play_circle_filled, size: 50),
                          ),
                        )
                      else if (sectionType == 'quiz')
                        Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.quiz, color: Colors.indigo),
                                    SizedBox(width: 8),
                                    Text(
                                      'Quiz: $sectionTitle',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // Navigate to quiz
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                  ),
                                  child: Text('Start Quiz'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                    ],
                  );
                }),

                // Module completion
                SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Module Completion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            module.isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color:
                                module.isCompleted ? Colors.green : Colors.grey,
                            size: 30,
                          ),
                          SizedBox(width: 8),
                          Text(
                            module.isCompleted
                                ? 'Completed'
                                : 'Mark as Completed',
                            style: TextStyle(
                              fontSize: 16,
                              color: module.isCompleted
                                  ? Colors.green
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          onModuleStatusChanged(
                              content, module, !module.isCompleted);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: module.isCompleted
                              ? Colors.red.shade400
                              : Colors.green,
                          minimumSize: Size(double.infinity, 48),
                        ),
                        child: Text(
                          module.isCompleted
                              ? 'Mark as Incomplete'
                              : 'Mark as Complete',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Model classes
enum Difficulty { beginner, intermediate, advanced }

class ContentModule {
  final String id;
  final String title;
  final String duration;
  bool isCompleted;
  int pointsEarned;

  ContentModule({
    required this.id,
    required this.title,
    required this.duration,
    this.isCompleted = false,
    this.pointsEarned = 0,
  });
}

class LearningContent {
  final String id;
  final String title;
  final String category;
  final String faculty;
  final String description;
  double progress;
  final Difficulty difficulty;
  final String imageUrl;
  final List<ContentModule> modules;
  final List<String> learningPathways;
  final String instructorName;

  LearningContent({
    required this.id,
    required this.title,
    required this.category,
    required this.faculty,
    required this.description,
    required this.progress,
    required this.difficulty,
    required this.imageUrl,
    required this.modules,
    required this.learningPathways,
    required this.instructorName,
  });
}
