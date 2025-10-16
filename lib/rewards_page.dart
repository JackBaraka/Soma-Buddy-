import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rewards',
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
              'Earn and Redeem Rewards',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete tasks, earn points, and unlock badges! Your progress and consistency will be rewarded.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (_user != null) // Check if user is logged in
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Text('Error fetching data');
                  }

                  var userData = snapshot.data!;
                  if (!userData.exists ||
                      userData.data() == null ||
                      !(userData.data() as Map<String, dynamic>)
                          .containsKey('points')) {
                    return const Text('No points data found for this user.');
                  }

                  int currentPoints = userData['points'] ?? 0;

                  return Text(
                    'Your Current Points: $currentPoints',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  );
                },
              )
            else
              const Text('Please log in to see your points.'),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rewards')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Text('Error fetching rewards');
                  }
                  var rewardData = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: rewardData.length,
                    itemBuilder: (context, index) {
                      var reward = rewardData[index];
                      return RewardCard(
                        title: reward['title'],
                        description: reward['description'],
                        points: reward['points'],
                        onRedeem: () async {
                          if (_user != null) {
                            var userRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(_user!.uid);

                            var userDoc = await userRef.get();
                            var userPoints = userDoc.data()?['points'] ?? 0;

                            if (userPoints >= reward['points']) {
                              await userRef.update({
                                'points':
                                    FieldValue.increment(-reward['points']),
                              });
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Reward redeemed!')),
                              );
                            } else {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Not enough points to redeem.')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please log in to redeem.')),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RewardCard extends StatelessWidget {
  final String title;
  final String description;
  final int points;
  final VoidCallback onRedeem;

  const RewardCard({
    super.key,
    required this.title,
    required this.description,
    required this.points,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$points pts',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16),
            ),
            const SizedBox(height: 4),
            IconButton(
              icon: const Icon(Icons.redeem, color: Colors.blue),
              onPressed: onRedeem,
            ),
          ],
        ),
      ),
    );
  }
}
