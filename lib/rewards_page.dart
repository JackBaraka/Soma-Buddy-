import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

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
            const Text(
              'Your Current Points: 250',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  RewardCard(
                    title: 'Active Learner Badge',
                    description:
                        'Complete 10 study sessions and earn this badge.',
                    points: 50,
                  ),
                  RewardCard(
                    title: 'Top Achiever',
                    description:
                        'Score 90%+ in quizzes to unlock this exclusive badge.',
                    points: 100,
                  ),
                  RewardCard(
                    title: 'Consistency Streak',
                    description:
                        'Study daily for 7 consecutive days and get rewarded.',
                    points: 75,
                  ),
                  RewardCard(
                    title: 'Discussion Leader',
                    description: 'Participate actively in 5 discussion forums.',
                    points: 60,
                  ),
                  RewardCard(
                    title: 'Quiz Master',
                    description:
                        'Complete 5 quizzes with an average score of 85% or higher.',
                    points: 80,
                  ),
                  RewardCard(
                    title: 'Collaboration Star',
                    description:
                        'Join a study group and contribute at least 3 helpful posts.',
                    points: 70,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Redeem Rewards'),
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

class RewardCard extends StatelessWidget {
  final String title;
  final String description;
  final int points;

  const RewardCard({
    super.key,
    required this.title,
    required this.description,
    required this.points,
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
            Icon(Icons.star, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}
