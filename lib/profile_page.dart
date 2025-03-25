import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  final TextEditingController nameController =
      TextEditingController(text: 'Jack Baraka');
  final TextEditingController studentIdController =
      TextEditingController(text: 'INTE/MG/1727/09/21');
  final TextEditingController courseController = TextEditingController(
      text: 'Bachelor of Science in Information Technology');
  final TextEditingController yearController =
      TextEditingController(text: '4th Year');
  final TextEditingController universityController =
      TextEditingController(text: 'Kabarak University');
  final TextEditingController emailController =
      TextEditingController(text: 'jack.baraka@student.kabarak.ac.ke');

  void toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void saveProfile() {
    setState(() {
      isEditing = false;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isEditing ? _buildEditableForm() : _buildProfileDisplay(),
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
        _buildTextField('Email', emailController),
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
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
