import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/coffee_loading_overlay.dart';
import 'transaction_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deletePasswordController = TextEditingController();

  User? _user;
  bool _isLoading = false;
  String _activeMenu = "Profile Information";

  @override
  void initState() {
    super.initState();
    refreshData();
    _apiService.authStateNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _apiService.authStateNotifier.removeListener(_onAuthChanged);
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  void _onAuthChanged() async {
    String? token = await _apiService.getToken();

    if (token == null) {
      if (mounted) {
        setState(() {
          _user = null;
          _isLoading = false;
          _nameController.clear();
          _emailController.clear();
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
      return;
    }

    if (mounted) {
      refreshData();
    }
  }

  Future<void> refreshData() async {
    final token = await _apiService.getToken();
    if (!mounted) return;
    if (token == null || _apiService.authStateNotifier.value == false) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _user = User.fromJson(result['user']);
        _nameController.text = _user?.name ?? '';
        _emailController.text = _user?.email ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Failed to load profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUpdateProfile() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
      );
      if (!mounted) return;
      _showSnackBar(result['message'] ?? 'Profile updated!');
      refreshData();
    } catch (e) {
      _showSnackBar("Update failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpdatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("New passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;
      _showSnackBar(result['message'] ?? 'Password updated!');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteAccount(String password) async {
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.deleteAccount(password);
      if (!mounted) return;
      _showSnackBar(result['message'] ?? "Account deleted.");
      navigator.pushNamedAndRemoveUntil('/main', (route) => false);
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      _showSnackBar("Deletion failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);
    try {
      await _apiService.logout();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Logout failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null && !_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('PROFILE')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("You are logged out"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AuthModal.show(context),
                child: const Text("GO TO LOGIN"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading && _user == null
          ? const Center(child: CoffeeLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAnimatedItem(0, _buildUserSummaryCard()),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(1, _buildQuickLinks()),
                  const SizedBox(height: 24),
                  if (_activeMenu == "Profile Information")
                    _buildAnimatedItem(
                      2,
                      _buildSection(
                        title: "Profile Information",
                        subtitle: "Update your account details.",
                        child: _buildProfileInfoForm(),
                      ),
                    ),
                  if (_activeMenu == "Update Password")
                    _buildAnimatedItem(
                      3,
                      _buildSection(
                        title: "Update Password",
                        subtitle: "Ensure your account is using a strong password.",
                        child: _buildUpdatePasswordForm(),
                      ),
                    ),
                  if (_activeMenu == "Delete Account")
                    _buildAnimatedItem(
                      4,
                      _buildSection(
                        title: "Delete Account",
                        subtitle: "This action is permanent.",
                        isDanger: true,
                        child: _buildDeleteAccountSection(),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfoForm() {
    return Column(
      children: [
        _buildTextField("Full Name", _nameController),
        const SizedBox(height: 16),
        _buildTextField(
          "Email Address",
          _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleUpdateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "UPDATE PROFILE",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
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
            child: Text(
              (_user?.name.isNotEmpty ?? false)
                  ? _user!.name[0].toUpperCase()
                  : "U",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user?.name ?? 'PREPARING...',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            _user?.email ?? "...",
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  "Balance",
                  "RM ${(_user?.balance ?? 0.0).toStringAsFixed(2)}",
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.border),
              Expanded(
                child: _buildMiniStat(
                  "Storage",
                  "${_user?.oz ?? 0} oz",
                  isPrimary: true,
                ),
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
          _buildNavLink(Icons.history, 'My Orders'),
          _buildNavLink(Icons.person_outline, 'Profile Information'),
          _buildNavLink(Icons.lock_outline, 'Update Password'),
          const Divider(),
          _buildNavLink(
            Icons.delete_outline,
            'Delete Account',
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(IconData icon, String label, {bool isDanger = false}) {
    final bool isActive = _activeMenu == label;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: isActive ? AppColors.primary.withValues(alpha: 0.05) : null,
      onTap: () {
        if (label == 'My Orders') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
          );
        } else {
          setState(() => _activeMenu = label);
        }
      },
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
            onPressed: _isLoading ? null : _handleUpdatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "SAVE PASSWORD",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
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

  Widget _buildAnimatedItem(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text(
              "This action is permanent. Please enter your password.",
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              "Password",
              _deletePasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handleDeleteAccount(
                            _deletePasswordController.text,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text("DELETE"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
