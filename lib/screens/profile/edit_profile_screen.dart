import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';

/// Edit Profile Screen — form to update user profile data.
///
/// Design adapted from the dark-mode HTML reference to the project's
/// light-mode "Volt" theme. Features:
/// - Cancel / Save actions in the header
/// - Avatar with camera badge + "Change Photo" button
/// - Full Name, Email (read-only), Height, Weight fields
/// - Date of Birth picker
/// - Gender & Fitness Goal dropdowns
/// - Delete Account danger zone
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  DateTime? _dateOfBirth;
  String _gender = 'Male';
  String _fitnessGoal = 'Build Muscle';
  bool _isSaving = false;

  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _goalOptions = [
    'Build Muscle',
    'Lose Weight',
    'Keep Fit',
    'Endurance Training',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _nameController = TextEditingController(text: user.fullName);
    _emailController = TextEditingController(text: user.email);
    _heightController = TextEditingController(
      text: user.heightCm?.toInt().toString() ?? '',
    );
    _weightController = TextEditingController(
      text: user.weightKg?.toInt().toString() ?? '',
    );
    _dateOfBirth = user.dateOfBirth;
    _gender = user.gender ?? 'Male';
    _fitnessGoal = user.fitnessGoal ?? 'Build Muscle';

    // Ensure values exist in lists
    if (!_genderOptions.contains(_gender)) _gender = 'Male';
    if (!_goalOptions.contains(_fitnessGoal)) _fitnessGoal = 'Build Muscle';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    final updatedUser = currentUser.copyWith(
      fullName: _nameController.text.trim(),
      heightCm: double.tryParse(_heightController.text),
      weightKg: double.tryParse(_weightController.text),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      fitnessGoal: _fitnessGoal,
    );

    final success = await authProvider.updateProfile(updatedUser);

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully! ✨',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // Return true to signal refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile. Please try again.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1995, 6, 15),
      firstDate: DateTime(1940),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      // For now, show a message. Full upload would require Supabase Storage.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo selected! Upload to Supabase Storage coming soon.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar ──────────────────────────────────────────────
            _buildTopBar(context),

            // ── Form Content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Section
                      _buildAvatarSection(context),

                      const SizedBox(height: 32),

                      // Full Name
                      _buildField(
                        context,
                        label: 'Full Name',
                        icon: Icons.person_rounded,
                        child: TextFormField(
                          controller: _nameController,
                          style: _inputTextStyle(colorScheme),
                          decoration: _inputDecoration(
                            context,
                            hint: 'Enter your name',
                            icon: Icons.person_rounded,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email (Read Only)
                      _buildField(
                        context,
                        label: 'Email',
                        icon: Icons.mail_rounded,
                        opacity: 0.6,
                        child: TextFormField(
                          controller: _emailController,
                          readOnly: true,
                          style: _inputTextStyle(colorScheme).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          decoration: _inputDecoration(
                            context,
                            hint: '',
                            icon: Icons.mail_rounded,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Height & Weight (2-column)
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              context,
                              label: 'Height (cm)',
                              icon: Icons.straighten_rounded,
                              child: TextFormField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                style: _inputTextStyle(colorScheme),
                                decoration: _inputDecoration(
                                  context,
                                  hint: '175',
                                  icon: Icons.straighten_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              context,
                              label: 'Weight (kg)',
                              icon: Icons.monitor_weight_rounded,
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                                style: _inputTextStyle(colorScheme),
                                decoration: _inputDecoration(
                                  context,
                                  hint: '72',
                                  icon: Icons.monitor_weight_rounded,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Date of Birth
                      _buildField(
                        context,
                        label: 'Date of Birth',
                        icon: Icons.calendar_today_rounded,
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: TextEditingController(
                                text: _dateOfBirth != null
                                    ? '${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                                    : 'Select date',
                              ),
                              readOnly: true,
                              style: _inputTextStyle(colorScheme),
                              decoration: _inputDecoration(
                                context,
                                hint: 'Select date',
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Gender Dropdown
                      _buildField(
                        context,
                        label: 'Gender',
                        icon: Icons.wc_rounded,
                        child: _buildDropdown(
                          context,
                          value: _gender,
                          items: _genderOptions,
                          icon: Icons.wc_rounded,
                          onChanged: (val) {
                            if (val != null) setState(() => _gender = val);
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Fitness Goal Dropdown
                      _buildField(
                        context,
                        label: 'Fitness Goal',
                        icon: Icons.fitness_center_rounded,
                        child: _buildDropdown(
                          context,
                          value: _fitnessGoal,
                          items: _goalOptions,
                          icon: Icons.fitness_center_rounded,
                          onChanged: (val) {
                            if (val != null) setState(() => _fitnessGoal = val);
                          },
                        ),
                      ),

                      // ── Danger Zone ──────────────────────────────────────
                      const SizedBox(height: 40),
                      Container(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 24),
                      _buildDangerZone(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR — Cancel | Title | Save
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Title
          Text(
            'Edit Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          // Save
          GestureDetector(
            onTap: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVATAR SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAvatarSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar with camera badge
          GestureDetector(
            onTap: _changePhoto,
            child: Stack(
              children: [
                // Avatar ring
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: user.avatarUrl != null &&
                              user.avatarUrl!.isNotEmpty
                          ? Image.network(
                              user.avatarUrl!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildAvatarFallback(
                                      context, user.fullName),
                            )
                          : _buildAvatarFallback(context, user.fullName),
                    ),
                  ),
                ),
                // Camera badge
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Change Photo text
          GestureDetector(
            onTap: _changePhoto,
            child: Text(
              'Change Photo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildAvatarFallback(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 110,
      height: 110,
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM FIELD BUILDER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget child,
    double opacity = 1.0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }

  TextStyle _inputTextStyle(ColorScheme colorScheme) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DROPDOWN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDropdown(
    BuildContext context, {
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                dropdownColor: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(vertical: 12),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DANGER ZONE — Delete Account
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDangerZone(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showDeleteDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Warning icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.error.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.warning_rounded,
                  size: 22,
                  color: colorScheme.error,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This action cannot be undone',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 400.ms);
  }

  void _showDeleteDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your account? '
          'This action is permanent and cannot be reversed. '
          'All your data, workout history, and progress will be lost.',
          style: GoogleFonts.plusJakartaSans(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account deletion requires server-side implementation.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete Forever',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
