import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          studentIdController.text = data['studentId'] ?? '';
          courseController.text = data['course'] ?? '';
          yearController.text = data['year'] ?? '';
          universityController.text = data['university'] ?? '';
          emailController.text = data['email'] ?? user!.email!;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  void toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> saveProfile() async {
    if (user == null) return;
    setState(() => isLoading = true);
    await _firestore.collection('users').doc(user!.uid).set({
      'name': nameController.text.trim(),
      'studentId': studentIdController.text.trim(),
      'course': courseController.text.trim(),
      'year': yearController.text.trim(),
      'university': universityController.text.trim(),
      'email': emailController.text.trim(),
    }, SetOptions(merge: true));
    setState(() {
      isEditing = false;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: toggleEdit,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:
                      isEditing ? _buildEditableForm() : _buildProfileDisplay(),
                ),
              ),
            ),
    );
  }

  Widget _buildEditableForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Name', nameController),
        _buildTextField('Student ID', studentIdController),
        _buildTextField('Email', emailController, readOnly: true),
        _buildTextField('Course', courseController),
        _buildTextField('Year', yearController),
        _buildTextField('University', universityController),
      ],
    );
  }

  Widget _buildProfileDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileItem('Name', nameController.text),
        _buildProfileItem('Student ID', studentIdController.text),
        _buildProfileItem('Email', emailController.text),
        _buildProfileItem('Course', courseController.text),
        _buildProfileItem('Year', yearController.text),
        _buildProfileItem('University', universityController.text),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modifications needed in main.dart - Update the ModuleCard onTap in the ModuleCard class:
