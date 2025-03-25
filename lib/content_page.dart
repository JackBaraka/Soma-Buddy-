import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  // Simulating course data with more detailed structure
  final List<LearningContent> _contents = [
    LearningContent(
      id: '001',
      title: 'Python Programming Fundamentals',
      category: 'Computer Science',
      description: 'Comprehensive introduction to Python programming',
      progress: 0.75,
      difficulty: Difficulty.intermediate,
      modules: [
        ContentModule(
          title: 'Basic Syntax and Variables',
          duration: '45 mins',
          isCompleted: true,
          pointsEarned: 50,
        ),
        ContentModule(
          title: 'Control Structures',
          duration: '60 mins',
          isCompleted: true,
          pointsEarned: 75,
        ),
        ContentModule(
          title: 'Functions and Modules',
          duration: '55 mins',
          isCompleted: false,
          pointsEarned: 0,
        ),
        ContentModule(
          title: 'Object-Oriented Programming',
          duration: '90 mins',
          isCompleted: false,
          pointsEarned: 0,
        ),
      ],
      learningPathways: ['Backend Development', 'Data Science'],
    ),
    LearningContent(
      id: '002',
      title: 'Web Development Essentials',
      category: 'Web Technologies',
      description: 'Comprehensive web development from HTML to JavaScript',
      progress: 0.5,
      difficulty: Difficulty.beginner,
      modules: [
        ContentModule(
          title: 'HTML Foundations',
          duration: '30 mins',
          isCompleted: true,
          pointsEarned: 40,
        ),
        ContentModule(
          title: 'CSS Styling Techniques',
          duration: '45 mins',
          isCompleted: false,
          pointsEarned: 0,
        ),
        ContentModule(
          title: 'JavaScript Fundamentals',
          duration: '60 mins',
          isCompleted: false,
          pointsEarned: 0,
        ),
      ],
      learningPathways: ['Frontend Development', 'Full Stack'],
    ),
  ];

  int _selectedTabIndex = 0;
  final List<LearningContent> _savedContents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soma Buddy Learning Hub'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Implement notification handling
            },
          ),
        ],
      ),
      body: Column(
        children: [
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

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
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
            ? Colors.teal.shade400
            : Colors.grey[200],
      ),
      child: Text(
        title,
        style: TextStyle(
          color: _selectedTabIndex == index ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildLearningContents() {
    return ListView.builder(
      itemCount: _contents.length,
      itemBuilder: (context, index) {
        final content = _contents[index];
        return _buildContentCard(content);
      },
    );
  }

  Widget _buildContentCard(LearningContent content) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: ListTile(
        leading: _buildDifficultyIcon(content.difficulty),
        title: Text(
          content.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.description),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: content.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                content.progress > 0.7 ? Colors.green : Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Category: ${content.category}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle_outline, color: Colors.teal),
          onPressed: () {
            // Add to saved courses logic
            setState(() {
              if (!_savedContents.contains(content)) {
                _savedContents.add(content);
              }
            });
          },
        ),
        onTap: () {
          // Navigate to content details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentDetailPage(content: content),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyIcon(Difficulty difficulty) {
    IconData icon;
    Color color;

    switch (difficulty) {
      case Difficulty.beginner:
        icon = Icons.star_border;
        color = Colors.green;
        break;
      case Difficulty.intermediate:
        icon = Icons.star_half;
        color = Colors.orange;
        break;
      case Difficulty.advanced:
        icon = Icons.star;
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color);
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
            'Personalized Recommendations Coming Soon!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedContents() {
    return _savedContents.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No saved courses yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _savedContents.length,
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
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
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
}

class ContentDetailPage extends StatelessWidget {
  final LearningContent content;

  const ContentDetailPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: ListView.builder(
        itemCount: content.modules.length,
        itemBuilder: (context, index) {
          final module = content.modules[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(module.title),
              subtitle: Text('Duration: ${module.duration}'),
              trailing: Checkbox(
                value: module.isCompleted,
                onChanged: (bool? value) {
                  // Implement module completion tracking
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class LearningContent {
  final String id;
  final String title;
  final String category;
  final String description;
  final double progress;
  final Difficulty difficulty;
  final List<ContentModule> modules;
  final List<String> learningPathways;

  LearningContent({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.progress,
    required this.difficulty,
    required this.modules,
    required this.learningPathways,
  });
}

class ContentModule {
  final String title;
  final String duration;
  bool isCompleted;
  int pointsEarned;

  ContentModule({
    required this.title,
    required this.duration,
    required this.isCompleted,
    required this.pointsEarned,
  });
}

enum Difficulty {
  beginner,
  intermediate,
  advanced,
}
