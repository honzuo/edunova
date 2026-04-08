import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _gender = TextEditingController();
  final _inst = TextEditingController();
  final _course = TextEditingController();
  final _goal = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<UserProvider>().loadUser();
      final u = context.read<UserProvider>().currentUser;
      if (u != null) {
        _name.text = u.fullName; _age.text = u.age == 0 ? '' : u.age.toString();
        _gender.text = u.gender; _inst.text = u.institution;
        _course.text = u.course; _goal.text = u.studyGoal;
      }
    });
  }

  @override
  void dispose() { _name.dispose(); _age.dispose(); _gender.dispose(); _inst.dispose(); _course.dispose(); _goal.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Avatar
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5856D6).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF5856D6)),
                  )),
                ),
                const SizedBox(height: 28),
                _field(_name, 'Full Name'),
                _field(_age, 'Age', keyboard: TextInputType.number),
                _field(_gender, 'Gender'),
                _field(_inst, 'Institution'),
                _field(_course, 'Course'),
                _field(_goal, 'Study Goal'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<UserProvider>().saveUser(
                      fullName: _name.text.trim(), age: int.tryParse(_age.text.trim()) ?? 0,
                      gender: _gender.text.trim(), institution: _inst.text.trim(),
                      course: _course.text.trim(), studyGoal: _goal.text.trim(),
                    );
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
                  },
                  child: const Text('Save Profile'),
                ),
              ]),
            ),
    );
  }

  Widget _field(TextEditingController c, String hint, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(hintText: hint)),
    );
  }
}
