import 'package:flutter/material.dart';
import 'main.dart'; // Import main.dart to use LoginPage

class LandingPage extends StatelessWidget {
const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  body: Container(
  decoration: BoxDecoration(
  gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Colors.teal[300]!, Colors.teal[600]!],
  ),
  ),
  child: SafeArea(
  child: SingleChildScrollView(
  child: Column(
  children: [
  // Header Section
  Padding(
  padding: const EdgeInsets.symmetric(
  vertical: 40.0, horizontal: 20.0),
  child: Column(
  children: [
  Icon(
  Icons.school,
  size: 100,
  color: Colors.white,
  ),
  const SizedBox(height: 20),
  const Text(
  'Welcome to SOMA BUDDY',
   textAlign: TextAlign.center,
   style: TextStyle(
   fontSize: 28,
   fontWeight: FontWeight.bold,
   color: Colors.white,
    ),
    ),
   const SizedBox(height: 10),
   const Text(
   'Your AI-Powered Learning Companion',
    textAlign: TextAlign.center,
    style: TextStyle(
    fontSize: 18,
    color: Colors.white70,
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 20),
    // Call to Action Section
    ElevatedButton(
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => const LoginPage()),
    );
    },
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.teal[700],
    padding: const EdgeInsets.symmetric(
    horizontal: 50, vertical: 15),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
    ),
    ),
    child: const Text(
    'Get Started',
    style: TextStyle(fontSize: 18),
    ),
    ),
    ],
    ),
    ),
    ),
    ),
    );
    }
    }
