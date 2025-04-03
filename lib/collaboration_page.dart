import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborationPage extends StatefulWidget {
  const CollaborationPage({super.key});

  @override
  State<CollaborationPage> createState() => _CollaborationPageState();
}

class _CollaborationPageState extends State<CollaborationPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createStudyGroup() async {
    if (_groupNameController.text.isEmpty) return;

    try {
      await _firestore.collection('study_groups').add({
        'groupName': _groupNameController.text,
        'members': 1,
        'createdBy':
            'user_id', // Replace with actual user ID if using authentication
        'description': 'Description of ${{_groupNameController.text}}',
      });
      _groupNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study Group Created Successfully!')),
      );
    } catch (e) {
      print('Error creating study group: $e');
    }
  }

  Future<void> _joinGroup(String groupId, int currentMembers) async {
    await _firestore.collection('study_groups').doc(groupId).update({
      'members': currentMembers + 1,
    });
  }

  Future<void> _leaveGroup(String groupId, int currentMembers) async {
    if (currentMembers > 1) {
      await _firestore.collection('study_groups').doc(groupId).update({
        'members': currentMembers - 1,
      });
    } else {
      await _firestore.collection('study_groups').doc(groupId).delete();
    }
  }

  void _showGroupDetails(String groupId, String groupName, int members) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(groupName),
          content: Text('Members: $members'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                _joinGroup(groupId, members);
                Navigator.pop(context);
              },
              child: const Text('Join Group'),
            ),
            TextButton(
              onPressed: () {
                _leaveGroup(groupId, members);
                Navigator.pop(context);
              },
              child: const Text('Leave Group'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Collaborate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join or Create Study Groups',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with peers, share notes, and discuss topics.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('study_groups').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Text('Error loading study groups.');
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No study groups available. Create one!');
                  }

                  final studyGroups = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: studyGroups.length,
                    itemBuilder: (context, index) {
                      final group = studyGroups[index];
                      final groupId = group.id;
                      final groupName = group['groupName'] ?? 'Untitled';
                      final members = group['members'] ?? 0;

                      return StudyGroupCard(
                        groupName: groupName,
                        members: members,
                        onTap: () =>
                            _showGroupDetails(groupId, groupName, members),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Study Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: _createStudyGroup,
                icon: const Icon(Icons.add),
                label: const Text('Create a Study Group'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudyGroupCard extends StatelessWidget {
  final String groupName;
  final int members;
  final VoidCallback onTap;

  const StudyGroupCard({
    super.key,
    required this.groupName,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          groupName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text('$members members'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
