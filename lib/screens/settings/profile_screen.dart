/// profile_screen.dart — User profile editor with Form validation.
///
/// Uses [Form] widget with [TextFormField] and [validator] callbacks
/// to ensure all user inputs are in the correct format before saving.
/// Profile photo can be set from camera or gallery using [image_picker].

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Form key to manage validation state
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for each input field
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _instCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  // Image picker instance for profile photo
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load current user data into form fields
    Future.microtask(() async {
      await context.read<UserProvider>().loadUser();
      final user = context.read<UserProvider>().currentUser;
      if (user != null) {
        _nameCtrl.text = user.fullName;
        _ageCtrl.text = user.age == 0 ? '' : user.age.toString();
        _genderCtrl.text = user.gender;
        _instCtrl.text = user.institution;
        _courseCtrl.text = user.course;
        _goalCtrl.text = user.studyGoal;
      }
    });
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _instCtrl.dispose();
    _courseCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════
  // ── Profile Photo Methods ──
  // ═══════════════════════════════

  /// Show bottom sheet with photo options (camera, gallery, remove).
  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _getImage(ImageSource.gallery);
              },
            ),
            // Show remove option only if photo exists
            if (context
                    .read<UserProvider>()
                    .currentUser
                    ?.profilePhotoPath
                    .isNotEmpty ==
                true)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<UserProvider>().removeProfilePhoto();
                },
              ),
          ]),
        ),
      ),
    );
  }

  /// Pick image from camera or gallery with compression.
  Future<void> _getImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      await context.read<UserProvider>().setProfilePhoto(File(picked.path));
    }
  }

  // ═══════════════════════════════
  // ── Form Submission ──
  // ═══════════════════════════════

  /// Validate form and save user profile to database.
  Future<void> _saveProfile() async {
    // Validate all form fields using the validators
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    await context.read<UserProvider>().saveUser(
          fullName: _nameCtrl.text.trim(),
          age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
          gender: _genderCtrl.text.trim(),
          institution: _instCtrl.text.trim(),
          course: _courseCtrl.text.trim(),
          studyGoal: _goalCtrl.text.trim(),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    }
  }

  // ═══════════════════════════════
  // ── Build UI ──
  // ═══════════════════════════════

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              // Wrap all fields in a Form widget for validation
              child: Form(
                key: _formKey,
                child: Column(children: [
                  // ── Avatar with Photo ──
                  _buildAvatar(user),
                  const SizedBox(height: 8),
                  Text('Tap to change photo',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const SizedBox(height: 24),

                  // ── Form Fields with Validation ──
                  _buildNameField(),
                  _buildAgeField(),
                  _buildGenderField(),
                  _buildInstitutionField(),
                  _buildCourseField(),
                  _buildGoalField(),

                  const SizedBox(height: 24),

                  // ── Save Button ──
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                ]),
              ),
            ),
    );
  }

  // ═══════════════════════════════
  // ── Avatar Widget ──
  // ═══════════════════════════════

  Widget _buildAvatar(dynamic user) {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5856D6).withAlpha(20),
              image: user.profilePhotoPath.isNotEmpty
                  ? DecorationImage(
                      image: FileImage(File(user.profilePhotoPath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.profilePhotoPath.isEmpty
                ? Center(
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5856D6),
                      ),
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── TextFormFields with Validators ──
  // ═══════════════════════════════════════════════

  /// Full Name — must contain only letters, spaces, hyphens, apostrophes.
  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _nameCtrl,
        keyboardType: TextInputType.name,
        decoration: const InputDecoration(
          hintText: 'Full Name',
          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your full name';
          }
          // Name must contain only letters, spaces, hyphens, apostrophes
          final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
          if (!nameRegex.hasMatch(value.trim())) {
            return 'Name can only contain letters, spaces, and hyphens';
          }
          if (value.trim().length < 2) {
            return 'Name must be at least 2 characters';
          }
          return null; // Valid
        },
      ),
    );
  }

  /// Age — must be a number between 1 and 100.
  Widget _buildAgeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _ageCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          hintText: 'Age',
          prefixIcon: Icon(Icons.cake_outlined, size: 20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your age';
          }
          final age = int.tryParse(value.trim());
          if (age == null) {
            return 'Please enter a valid number';
          }
          if (age < 1 || age > 100) {
            return 'Age must be between 1 and 100';
          }
          return null; // Valid
        },
      ),
    );
  }

  /// Gender — must not be empty.
  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _genderCtrl,
        decoration: const InputDecoration(
          hintText: 'Gender',
          prefixIcon: Icon(Icons.wc_outlined, size: 20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your gender';
          }
          return null;
        },
      ),
    );
  }

  /// Institution — must not be empty.
  Widget _buildInstitutionField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _instCtrl,
        decoration: const InputDecoration(
          hintText: 'Institution',
          prefixIcon: Icon(Icons.school_outlined, size: 20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your institution';
          }
          return null;
        },
      ),
    );
  }

  /// Course — must not be empty.
  Widget _buildCourseField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _courseCtrl,
        decoration: const InputDecoration(
          hintText: 'Course',
          prefixIcon: Icon(Icons.menu_book_outlined, size: 20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your course';
          }
          return null;
        },
      ),
    );
  }

  /// Study Goal — optional, but if provided must be at least 3 chars.
  Widget _buildGoalField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _goalCtrl,
        decoration: const InputDecoration(
          hintText: 'Study Goal',
          prefixIcon: Icon(Icons.flag_outlined, size: 20),
        ),
        validator: (value) {
          // Study goal is optional
          if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
            return 'Goal must be at least 3 characters';
          }
          return null;
        },
      ),
    );
  }
}
