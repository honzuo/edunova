import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final fullNameController = TextEditingController();
  final ageController = TextEditingController();
  final genderController = TextEditingController();
  final institutionController = TextEditingController();
  final courseController = TextEditingController();
  final studyGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<UserProvider>().loadUser();
      final user = context.read<UserProvider>().currentUser;

      if (user != null) {
        fullNameController.text = user.fullName;
        ageController.text = user.age == 0 ? '' : user.age.toString();
        genderController.text = user.gender;
        institutionController.text = user.institution;
        courseController.text = user.course;
        studyGoalController.text = user.studyGoal;
      }
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    ageController.dispose();
    genderController.dispose();
    institutionController.dispose();
    courseController.dispose();
    studyGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            TextField(
              controller: genderController,
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            TextField(
              controller: institutionController,
              decoration: const InputDecoration(labelText: 'Institution'),
            ),
            TextField(
              controller: courseController,
              decoration: const InputDecoration(labelText: 'Course'),
            ),
            TextField(
              controller: studyGoalController,
              decoration: const InputDecoration(labelText: 'Study Goal'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await context.read<UserProvider>().saveUser(
                  fullName: fullNameController.text.trim(),
                  age: int.tryParse(ageController.text.trim()) ?? 0,
                  gender: genderController.text.trim(),
                  institution: institutionController.text.trim(),
                  course: courseController.text.trim(),
                  studyGoal: studyGoalController.text.trim(),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved')),
                  );
                }
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}