// ignore_for_file: use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

enum UserRole {
  student,
  educator,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class OfflineModePage extends StatefulWidget {
  const OfflineModePage({super.key});

  @override
  OfflineModePageState createState() => OfflineModePageState();
}

class OfflineModePageState extends State<OfflineModePage>
    with SingleTickerProviderStateMixin {
  List<html.File> downloadedFiles = [];
  Map<String, String> fileUrls = {}; // Store URLs for downloaded files
  List<DocumentSnapshot> assignments = [];
  List<DocumentSnapshot> revisionMaterials = [];
  List<DocumentSnapshot> submittedAssignments = [];
  bool _isLoading = true;
  late TabController _tabController;
  UserRole _userRole =
      UserRole.student; // Default role, will be updated from Firebase auth

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRole();
    _loadFirestoreData();
    // No need to load downloaded files on init for web since we'll be opening them directly
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc['role'] == 'educator'
                ? UserRole.educator
                : UserRole.student;
          });
        }
      }
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  Future<void> _loadFirestoreData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to access your content')),
        );
        return;
      }

      // Load assignments
      QuerySnapshot assignmentSnapshot;
      if (_userRole == UserRole.educator) {
        assignmentSnapshot = await FirebaseFirestore.instance
            .collection('assignments')
            .where('educatorId', isEqualTo: user.uid)
            .get();
      } else {
        assignmentSnapshot = await FirebaseFirestore.instance
            .collection('assignments')
            .where('studentIds', arrayContains: user.uid)
            .get();
      }

      // Load revision materials
      final revisionSnapshot = await FirebaseFirestore.instance
          .collection('revisionMaterials')
          .get();

      // Load submitted assignments
      QuerySnapshot submittedSnapshot;
      if (_userRole == UserRole.educator) {
        submittedSnapshot = await FirebaseFirestore.instance
            .collection('submittedAssignments')
            .where('educatorId', isEqualTo: user.uid)
            .where('graded', isEqualTo: false)
            .get();
      } else {
        submittedSnapshot = await FirebaseFirestore.instance
            .collection('submittedAssignments')
            .where('studentId', isEqualTo: user.uid)
            .get();
      }

      setState(() {
        assignments = assignmentSnapshot.docs;
        revisionMaterials = revisionSnapshot.docs;
        submittedAssignments = submittedSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: $e')),
        );
      }
    }
  }

  void _openFile(String url, String fileName) {
    // For web, we'll open the file in a new tab
    html.window.open(url, '_blank');
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // For web, download by creating an anchor element
      html.AnchorElement anchorElement = html.AnchorElement(href: url);
      anchorElement.download = fileName;
      anchorElement.click();

      // Store the URL for reference (we can't actually store files on web)
      setState(() {
        fileUrls[fileName] = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName downloading now')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAssignment(DocumentSnapshot assignment) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
        withData: true, // Important for web to get file data
      );

      if (result == null) return;

      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      final fileName =
          '${user!.uid}_${assignment.id}_${result.files.single.name}';

      // Upload to Firebase Storage (works on web)
      final storageRef =
          FirebaseStorage.instance.ref().child('submissions/$fileName');

      // Get bytes from file for web upload
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        throw Exception('Failed to read file data');
      }

      // Upload as data bytes for web
      await storageRef.putData(bytes);
      final downloadUrl = await storageRef.getDownloadURL();

      // Create submission record in Firestore
      await FirebaseFirestore.instance.collection('submittedAssignments').add({
        'assignmentId': assignment.id,
        'assignmentTitle': assignment['title'],
        'studentId': user.uid,
        'educatorId': assignment['educatorId'],
        'submissionUrl': downloadUrl,
        'fileName': result.files.single.name,
        'submittedAt': FieldValue.serverTimestamp(),
        'graded': false,
        'grade': null,
        'feedback': null,
      });

      await _loadFirestoreData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting assignment: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _gradeAssignment(DocumentSnapshot submission) async {
    final gradeController = TextEditingController();
    final feedbackController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grade Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                hintText: 'Enter numerical grade',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'Enter feedback for the student',
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (gradeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a grade')),
                  );
                  return;
                }

                final grade = int.parse(gradeController.text);
                if (grade < 0 || grade > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Grade must be between 0 and 100')),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('submittedAssignments')
                    .doc(submission.id)
                    .update({
                  'graded': true,
                  'grade': grade,
                  'feedback': feedbackController.text,
                  'gradedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                await _loadFirestoreData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Assignment graded successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error grading assignment: $e')),
                );
              }
            },
            child: const Text('Submit Grade'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewAssignment() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Assignment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter assignment title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter assignment description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'Select due date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    dueDateController.text =
                        '${picked.day}/${picked.month}/${picked.year}';
                    selectedDate = picked;
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Attachment (optional):'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach File'),
                onPressed: () async {
                  // File attachment logic would go here
                  // This is just a placeholder for the dialog UI
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a due date')),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                await FirebaseFirestore.instance.collection('assignments').add({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'dueDate': selectedDate,
                  'educatorId': user!.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                  'studentIds':
                      [], // This would be populated from your class/student management system
                  'attachmentUrl':
                      null, // Would be populated if attachment was uploaded
                });

                Navigator.pop(context);
                await _loadFirestoreData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Assignment created successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating assignment: $e')),
                );
              }
            },
            child: const Text('Create Assignment'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRevisionMaterial() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Uint8List? selectedFileBytes;
    String? fileName;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Revision Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter material title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter material description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(fileName ?? 'Upload File'),
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          'pdf',
                          'doc',
                          'docx',
                          'ppt',
                          'pptx',
                          'mp4',
                          'mp3'
                        ],
                        withData: true, // Important for web to get file data
                      );

                      if (result != null) {
                        selectedFileBytes = result.files.single.bytes;
                        setDialogState(() {
                          fileName = result.files.single.name;
                        });
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                if (selectedFileBytes == null || fileName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please upload a file')),
                  );
                  return;
                }

                setState(() {
                  _isLoading = true;
                });
                Navigator.pop(context);

                final user = FirebaseAuth.instance.currentUser;
                final storageRef = FirebaseStorage.instance
                    .ref()
                    .child('revisionMaterials/${user!.uid}_$fileName');

                // Upload bytes for web
                await storageRef.putData(selectedFileBytes!);
                final downloadUrl = await storageRef.getDownloadURL();

                await FirebaseFirestore.instance
                    .collection('revisionMaterials')
                    .add({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'fileUrl': downloadUrl,
                  'fileName': fileName,
                  'uploadedBy': user.uid,
                  'uploadedAt': FieldValue.serverTimestamp(),
                });

                await _loadFirestoreData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Revision material added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding revision material: $e')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Upload Material'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String path) {
    if (path.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (path.endsWith('.mp4')) return Icons.video_library;
    if (path.endsWith('.mp3')) return Icons.music_note;
    if (path.endsWith('.docx') || path.endsWith('.doc'))
      return Icons.description;
    if (path.endsWith('.pptx') || path.endsWith('.ppt')) return Icons.slideshow;
    return Icons.file_present;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educational Content'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                text: _userRole == UserRole.student
                    ? 'Assignments'
                    : 'Manage Assignments'),
            const Tab(text: 'Revision Material'),
            const Tab(text: 'Web Links'),
          ],
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadFirestoreData();
            },
            tooltip: 'Refresh Content',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Assignments Tab
                _buildAssignmentsTab(),

                // Revision Materials Tab
                _buildRevisionMaterialsTab(),

                // Web Links Tab (replaces Downloaded Files for web)
                _buildWebLinksTab(),
              ],
            ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show different FAB based on selected tab and user role
    if (_isLoading) return null;

    if (_tabController.index == 0 && _userRole == UserRole.educator) {
      // For assignments tab as educator
      return FloatingActionButton(
        onPressed: _addNewAssignment,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      );
    } else if (_tabController.index == 1 && _userRole == UserRole.educator) {
      // For revision materials tab as educator
      return FloatingActionButton(
        onPressed: _addRevisionMaterial,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      );
    }

    return null;
  }

  Widget _buildAssignmentsTab() {
    if (_userRole == UserRole.student) {
      return _buildStudentAssignmentsView();
    } else {
      return _buildEducatorAssignmentsView();
    }
  }

  Widget _buildStudentAssignmentsView() {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No assignments available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final Map<String, dynamic> data =
            assignment.data() as Map<String, dynamic>;

        // Check if this assignment has been submitted
        final isSubmitted = submittedAssignments
            .any((submission) => submission['assignmentId'] == assignment.id);

        // Find submission if it exists to check grade
        DocumentSnapshot? submission;
        bool isGraded = false;

        try {
          submission = submittedAssignments.firstWhere(
            (s) => s['assignmentId'] == assignment.id,
          );
          isGraded = submission['graded'] == true;
        } catch (e) {
          // No submission found
          submission = null;
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? 'No description provided',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${data['dueDate']?.toDate().toString().substring(0, 10) ?? 'Not specified'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status and action buttons
                if (isSubmitted && isGraded && submission != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Grade: ${submission['grade']}/100',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (submission['feedback'] != null &&
                            submission['feedback'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Feedback: ${submission['feedback']}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else if (isSubmitted)
                  Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Submitted - Awaiting Grade',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _submitAssignment(assignment),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Submit Assignment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),

                // If there's an attachment from teacher
                if (data['attachmentUrl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download Instructions'),
                      onPressed: () => _downloadFile(
                        data['attachmentUrl'],
                        data['attachmentName'] ??
                            'assignment_${assignment.id}.pdf',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEducatorAssignmentsView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Submissions to Grade (${submittedAssignments.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (submittedAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No pending submissions to grade',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: submittedAssignments.length,
              itemBuilder: (context, index) {
                final submission = submittedAssignments[index];
                final Map<String, dynamic> data =
                    submission.data() as Map<String, dynamic>;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.assignment_turned_in,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      data['assignmentTitle'] ?? 'Unnamed Assignment',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Submitted: ${(data['submittedAt'] as Timestamp).toDate().toString().substring(0, 10)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.blue,
                          ),
                          onPressed: () => _openFile(
                            data['submissionUrl'],
                            data['fileName'] ?? 'submission.pdf',
                          ),
                          tooltip: 'View Submission',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.grade,
                            color: Colors.green,
                          ),
                          onPressed: () => _gradeAssignment(submission),
                          tooltip: 'Grade Assignment',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Your Assignments (${assignments.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No assignments created yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              final Map<String, dynamic> data =
                  assignment.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(
                      Icons.assignment,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Unnamed Assignment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due: ${data['dueDate']?.toDate().toString().substring(0, 10) ?? 'Not specified'}',
                      ),
                      Text(
                        'Students: ${(data['studentIds'] as List?)?.length ?? 0}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Edit assignment functionality would go here
                        },
                        tooltip: 'Edit Assignment',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Assignment?'),
                              content: const Text(
                                  'This will permanently delete the assignment. This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('assignments')
                                  .doc(assignment.id)
                                  .delete();
                              await _loadFirestoreData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Assignment deleted')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error deleting assignment: $e')),
                              );
                            }
                          }
                        },
                        tooltip: 'Delete Assignment',
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionMaterialsTab() {
    if (revisionMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No revision materials available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: revisionMaterials.length,
      itemBuilder: (context, index) {
        final material = revisionMaterials[index];
        final Map<String, dynamic> data =
            material.data() as Map<String, dynamic>;
        final String fileName = data['fileName'] ?? 'material.pdf';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getFileIcon(fileName),
                      color: Colors.deepPurple,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'Unnamed Material',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data['description'] != null &&
                    data['description'].isNotEmpty)
                  Text(
                    data['description'],
                    style: TextStyle(
                      color: Colors.grey[800],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Added: ${(data['uploadedAt'] as Timestamp).toDate().toString().substring(0, 10)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.remove_red_eye),
                          label: const Text('View'),
                          onPressed: () => _openFile(
                            data['fileUrl'],
                            fileName,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          onPressed: () => _downloadFile(
                            data['fileUrl'],
                            fileName,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_userRole == UserRole.educator &&
                    data['uploadedBy'] ==
                        FirebaseAuth.instance.currentUser?.uid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Material?'),
                            content: const Text(
                                'This will permanently delete this material. This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('revisionMaterials')
                                .doc(material.id)
                                .delete();
                            await _loadFirestoreData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Material deleted')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error deleting material: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebLinksTab() {
    // Web links collection for educational resources
    List<Map<String, String>> webLinks = [
      {
        'title': 'Khan Academy',
        'description': 'Free online education platform for all subjects',
        'url': 'https://www.khanacademy.org/'
      },
      {
        'title': 'Coursera',
        'description': 'Platform for online courses from top universities',
        'url': 'https://www.coursera.org/'
      },
      {
        'title': 'MIT OpenCourseWare',
        'description': 'Free access to MIT course materials',
        'url': 'https://ocw.mit.edu/'
      },
      {
        'title': 'Wolfram Alpha',
        'description': 'Computational intelligence for mathematics and science',
        'url': 'https://www.wolframalpha.com/'
      },
      {
        'title': 'Project Gutenberg',
        'description': 'Free library of classic books and literature',
        'url': 'https://www.gutenberg.org/'
      },
      {
        'title': 'TED Talks',
        'description': 'Thought-provoking videos on various topics',
        'url': 'https://www.ted.com/talks'
      },
      {
        'title': 'NASA Education',
        'description': 'Space and science resources for students',
        'url': 'https://www.nasa.gov/education/'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: webLinks.length,
      itemBuilder: (context, index) {
        final link = webLinks[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(
                Icons.language,
                color: Colors.white,
              ),
            ),
            title: Text(
              link['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(link['description']!),
            trailing: ElevatedButton(
              onPressed: () {
                html.window.open(link['url']!, '_blank');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Visit'),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Educational App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OfflineModePage(),
    );
  }
}
