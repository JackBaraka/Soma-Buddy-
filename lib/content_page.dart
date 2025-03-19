import 'package:flutter/material.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

// Define the ModulesPage class
class ModulesPage extends StatelessWidget {
  final String moduleTitle;

  const ModulesPage({Key? key, required this.moduleTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(moduleTitle),
      ),
      body: Center(
        child: Text(
          'Content for $moduleTitle',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// Data Models
// Removed duplicate ContentCourse class definition

// Data Models
// Removed duplicate ContentCourse class definition

// Data Models
// Removed duplicate ContentCourse class definition

class _ContentPageState extends State<ContentPage> {
  void _navigateToModule(String moduleTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModulesPage(moduleTitle: moduleTitle),
      ),
    );
  }
  // Sample content data - in a real app, this would come from a database or API
  final List<ContentCourse> _courses = [
    ContentCourse(
      title: 'Programming Basics',
      description: 'Learn the fundamentals of programming',
      progress: 0.75,
      icon: Icons.code,
      color: Colors.blue,
      modules: [
        ContentModule(
          title: 'Variables and Data Types',
          duration: '45 mins',
          isCompleted: true,
        ),
          duration: '45 mins',
          isCompleted: true,
        ),
        ContentModule(
          title: 'Control Structures',
          duration: '60 mins',
          isCompleted: true,
        ),
        ContentModule(
          title: 'Functions',
          duration: '55 mins',
          isCompleted: true,
        ),
        ContentModule(
          title: 'Object-Oriented Programming',
          duration: '90 mins',
          isCompleted: false,
        ),
      ],
    ),
    ContentCourse(
      title: {'Web Development Fundamentals'},
      description: 'HTML, CSS, and JavaScript basics',
      progress: 0.5,
      icon: Icons.web,
      color: Colors.orange,
      modules: [
        ContentModule(
          title: 'HTML Structure',
          duration: '30 mins',
          isCompleted: true,
        ),
        ContentModule(
          title: 'CSS Styling',
          duration: '45 mins',
          isCompleted: true,
        ),
        ContentModule(
          title: 'JavaScript Basics',
          duration: '60 mins',
          isCompleted: false,
        ),
        ContentModule(
          title: 'Building a Simple Website',
          duration: '120 mins',
          isCompleted: false,
        ),
      ],
    ),
    ContentCourse(
      title: 'Mobile App Development',
      description: 'Flutter and Dart programming',
      progress: 0.25,
      icon: Icons.smartphone,
      color: Colors.green,
      modules: [
        ContentModule(
          title: 'Dart Programming',
          duration: '60 mins',
          isCompleted: true,
        ),
        ContentModule(
          title: 'Flutter Widgets',
          duration: '90 mins',
          isCompleted: false,
        ),
        ContentModule(
          title: 'Navigation and Routing',
          duration: '45 mins',
          isCompleted: false,
        ),
        ContentModule(
          title: 'Building a Complete App',
          duration: '180 mins',
          isCompleted: false,
        ),
      ],
    ),
  ];

  final List<ContentRecommendation> _recommendations = [
    ContentRecommendation(
      title: 'Data Structures',
      description: 'Algorithms and data structures fundamentals',
      icon: Icons.storage,
      color: Colors.purple,
    ),
    ContentRecommendation(
      title: 'UI/UX Design',
      description: 'Principles of user interface design',
      icon: Icons.design_services,
      color: Colors.pink,
    ),
    ContentRecommendation(
      title: 'Database Management',
      description: 'SQL and NoSQL database concepts',
      icon: Icons.data_array,
      color: Colors.teal,
    ),
  ];

  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filter functionality
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabButton('My Courses', 0),
                _buildTabButton('Recommended', 1),
                _buildTabButton('Saved', 2),
              ],
            ),
          ),
          // Content based on selected tab
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildMyCourses()
                : _selectedTabIndex == 1
                    ? _buildRecommendedCourses()
                    : _buildSavedCourses(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement add new content functionality
          _showAddContentDialog();
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedTabIndex == index
                ? Colors.teal
                : Colors.grey.withOpacity(0.1),
            foregroundColor:
                _selectedTabIndex == index ? Colors.white : Colors.black87,
            elevation: _selectedTabIndex == index ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(title),
        ),
      ),
    );
  }

  Widget _buildMyCourses() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              _showCourseDetails(course);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: course.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          course.icon,
                          color: course.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              course.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress: ${(course.progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: course.progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                course.color,
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          // Continue learning button
                          _showCourseDetails(course);
                        },
                        icon: const Icon(Icons.play_circle_filled),
                        color: course.color,
                        tooltip: 'Continue Learning',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendedCourses() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recommended Based on Your Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = _recommendations[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  _showRecommendationDetails(recommendation);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: recommendation.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          recommendation.icon,
                          size: 40,
                          color: recommendation.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        recommendation.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _showRecommendationDetails(recommendation);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: recommendation.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Trending Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.blue[700],
                  ),
                ),
                title: Text('Trending Course ${index + 1}'),
                subtitle: Text('Enrolled by ${1000 + index * 200} students'),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Course added to your list!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enroll'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSavedCourses() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved courses yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Courses you save will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedTabIndex = 1; // Switch to recommended tab
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Browse Recommended Courses'),
          ),
        ],
      ),
    );
  }

  void _showCourseDetails(ContentCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress: ${(course.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: course.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            course.color,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Course Modules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: course.modules.length,
                  itemBuilder: (context, index) {
                    final module = course.modules[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: module.isCompleted
                              ? Colors.green
                              : Colors.grey[300],
                          child: Icon(
                            module.isCompleted ? Icons.check : Icons.play_arrow,
                            color: module.isCompleted
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
                        title: Text(
                          module.title,
                          style: TextStyle(
                            fontWeight: module.isCompleted
                                ? FontWeight.normal
                                : FontWeight.bold,
                            decoration: module.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text('Duration: ${module.duration}'),
                        trailing: module.isCompleted
                            ? const Icon(Icons.done_all, color: Colors.green)
                            : ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Starting module: ${module.title}'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: course.color,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Start'),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Continuing where you left off...'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: course.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Continue Learning',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecommendationDetails(ContentRecommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(recommendation.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(recommendation.description),
              const SizedBox(height: 16),
              const Text(
                'This course is recommended based on your learning history and profile preferences.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              const Text('Key topics:'),
              const SizedBox(height: 8),
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Topic ${index + 1}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Course added to your list!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: recommendation.color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add to My Courses'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Courses'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter keywords...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              // Implement search logic
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Search feature coming soon!'),
                  ),
                );
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Courses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Categories:'),
              CheckboxListTile(
                title: const Text('Programming'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Web Development'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Mobile Development'),
                value: true,
                onChanged: (value) {},
              ),
              const Divider(),
              const Text('Difficulty:'),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Beginner'),
                      selected: true,
                      onSelected: (value) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Intermediate'),
                      selected: false,
                      onSelected: (value) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Advanced'),
                      selected: false,
                      onSelected: (value) {},
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filter applied!'),
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Content'),
          content: const Text(
              'This feature will allow you to add your own learning materials or suggest new courses.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature coming soon!'),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Data Models
class ContentCourse {
  final String title;
  final String description;
  final double progress;
  final IconData icon;
  final Color color;
  final List<ContentModule> modules;

  ContentCourse({
    required this.title,
    required this.description,
    required this.progress,
    required this.icon,
    required this.color,
    required this.modules,
  });
}

class ContentModule {
  final String title;
  final String duration;
  final bool isCompleted;

  ContentModule({
    required this.title,
    required this.duration,
    required this.isCompleted,
  });
}

class ContentRecommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  ContentRecommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
