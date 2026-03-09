import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController(
    text: "User Name",
  ); // Mock initial value
  final _emailController = TextEditingController(
    text: "user@example.com",
  ); // Mock initial value
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Summary Card
            _buildUserSummaryCard(),
            const SizedBox(height: 24),

            // Navigation / Quick Links (Simulating the sidebar in Web)
            _buildQuickLinks(),
            const SizedBox(height: 24),

            // Profile Information Form
            _buildSection(
              title: "Profile Information",
              subtitle:
                  "Update your account's profile information and email address.",
              child: _buildProfileInfoForm(),
            ),
            const SizedBox(height: 24),

            // Update Password Form
            _buildSection(
              title: "Update Password",
              subtitle:
                  "Ensure your account is using a long, random password to stay secure.",
              child: _buildUpdatePasswordForm(),
            ),
            const SizedBox(height: 24),

            // Delete Account Section
            _buildSection(
              title: "Delete Account",
              subtitle:
                  "Once your account is deleted, all of its resources and data will be permanently deleted.",
              isDanger: true,
              child: _buildDeleteAccountSection(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: const Text(
              "U", // First letter of name
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "User Name",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const Text(
            "user@example.com",
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildMiniStat("Balance", "RM 25.50")),
              Container(width: 1, height: 30, color: AppColors.border),
              Expanded(
                child: _buildMiniStat("Storage", "2500 oz", isPrimary: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {bool isPrimary = false}) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isPrimary ? AppColors.primary : AppColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinks() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildNavLink(Icons.person_outline, "Profile Information", true),
          _buildNavLink(Icons.lock_outline, "Update Password", false),
          _buildNavLink(
            Icons.warning_amber_rounded,
            "Delete Account",
            false,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(
    IconData icon,
    String label,
    bool isActive, {
    bool isDanger = false,
  }) {
    Color color = isDanger
        ? Colors.red
        : (isActive ? AppColors.primary : AppColors.textMain);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 16,
        color: AppColors.textMuted,
      ),
      onTap: () {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: isActive ? AppColors.primary.withValues(alpha: 0.05) : null,
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
    bool isDanger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDanger
              ? Colors.red.withValues(alpha: 0.2)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileInfoForm() {
    return Column(
      children: [
        _buildTextField("Name", _nameController),
        const SizedBox(height: 16),
        _buildTextField(
          "Email",
          _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "SAVE",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatePasswordForm() {
    return Column(
      children: [
        _buildTextField(
          "Current Password",
          _currentPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "New Password",
          _newPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Confirm Password",
          _confirmPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "SAVE",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showDeleteConfirmation(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "DELETE ACCOUNT",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure you want to delete your account?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text(
              "Once your account is deleted, all of its resources and data will be permanently deleted. Please enter your password to confirm.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              "Password",
              TextEditingController(),
              isPassword: true,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "DELETE",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

extension on BoxDecoration {
  // Custom extension to simulate the border-b-8 in Tailwind if needed, but for now we used borderEdge logic inside _buildSection
}
