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
                  _buildAnimatedItem(
                      0,
                      RepaintBoundary(
                        child: UserSummaryCard(user: _user),
                      )),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                      1,
                      RepaintBoundary(
                        child: QuickLinks(
                          activeMenu: _activeMenu,
                          onMenuChanged: (menu) {
                            setState(() => _activeMenu = menu);
                          },
                        ),
                      )),
                  const SizedBox(height: 24),
                  if (_activeMenu == "App Appearance")
                    _buildAnimatedItem(
                      3,
                      const ProfileSection(
                        title: "App Appearance",
                        subtitle:
                            "Customize how Coffee Plus+ looks on your device.",
                        child: AppearanceSection(),
                      ),
                    ),
                  if (_activeMenu == "Profile Information")
                    _buildAnimatedItem(
                      2,
                      ProfileSection(
                        title: "Profile Information",
                        subtitle: "Update your account details.",
                        child: ProfileInfoForm(
                          nameController: _nameController,
                          emailController: _emailController,
                          isLoading: _isLoading,
                          onUpdate: _handleUpdateProfile,
                        ),
                      ),
                    ),
                  if (_activeMenu == "Update Password")
                    _buildAnimatedItem(
                      3,
                      ProfileSection(
                        title: "Update Password",
                        subtitle:
                            "Ensure your account is using a strong password.",
                        child: UpdatePasswordForm(
                          currentPasswordController: _currentPasswordController,
                          newPasswordController: _newPasswordController,
                          confirmPasswordController: _confirmPasswordController,
                          isLoading: _isLoading,
                          onUpdate: _handleUpdatePassword,
                        ),
                      ),
                    ),
                  if (_activeMenu == "Delete Account")
                    _buildAnimatedItem(
                      4,
                      ProfileSection(
                        title: "Delete Account",
                        subtitle: "This action is permanent.",
                        isDanger: true,
                        child: DeleteAccountSection(
                          onDelete: _showDeleteConfirmation,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
        padding: EdgeInsets.fromLTRB(
            32, 32, 32, 32 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            Text(
              "This action is permanent. Please enter your password.",
              style: TextStyle(color: context.appTextMuted),
            ),
            const SizedBox(height: 24),
            ProfileTextField(
              label: "Password",
              controller: _deletePasswordController,
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

// ==========================================
// 6. 独立优化组件 (Standalone Optimized Widgets)
// ==========================================

class UserSummaryCard extends StatelessWidget {
  final User? user;

  const UserSummaryCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              (user?.name.isNotEmpty ?? false)
                  ? user!.name[0].toUpperCase()
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
            user?.name ?? 'PREPARING...',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            user?.email ?? "...",
            style: TextStyle(color: context.appTextMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: MiniStat(
                  label: "Balance",
                  value: "RM ${(user?.balance ?? 0.0).toStringAsFixed(2)}",
                ),
              ),
              Container(width: 1, height: 30, color: context.appBorder),
              Expanded(
                child: MiniStat(
                  label: "Storage",
                  value: "${user?.oz ?? 0} oz",
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: context.appTextMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isPrimary ? context.appPrimary : context.appTextMain,
          ),
        ),
      ],
    );
  }
}

class QuickLinks extends StatelessWidget {
  final String activeMenu;
  final ValueChanged<String> onMenuChanged;

  const QuickLinks({
    super.key,
    required this.activeMenu,
    required this.onMenuChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          NavLink(
            icon: Icons.history,
            label: 'My Orders',
            isActive: activeMenu == 'My Orders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionHistoryScreen(),
              ),
            ),
          ),
          NavLink(
            icon: Icons.palette_outlined,
            label: 'App Appearance',
            isActive: activeMenu == 'App Appearance',
            onTap: () => onMenuChanged('App Appearance'),
          ),
          NavLink(
            icon: Icons.person_outline,
            label: 'Profile Information',
            isActive: activeMenu == 'Profile Information',
            onTap: () => onMenuChanged('Profile Information'),
          ),
          NavLink(
            icon: Icons.lock_outline,
            label: 'Update Password',
            isActive: activeMenu == 'Update Password',
            onTap: () => onMenuChanged('Update Password'),
          ),
          const Divider(),
          NavLink(
            icon: Icons.delete_outline,
            label: 'Delete Account',
            isDanger: true,
            isActive: activeMenu == 'Delete Account',
            onTap: () => onMenuChanged('Delete Account'),
          ),
        ],
      ),
    );
  }
}

class NavLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDanger;
  final VoidCallback onTap;

  const NavLink({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color = isDanger
        ? Colors.red
        : (isActive ? context.appPrimary : context.appTextMain);
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
      trailing: Icon(
        Icons.chevron_right,
        size: 16,
        color: context.appTextMuted,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: isActive ? context.appPrimary.withValues(alpha: 0.05) : null,
      onTap: onTap,
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool isDanger;

  const ProfileSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDanger
              ? Colors.red.withValues(alpha: 0.2)
              : context.appBorder,
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
            style: TextStyle(fontSize: 13, color: context.appTextMuted),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: apiService.themeModeNotifier,
      builder: (context, currentMode, _) {
        return Column(
          children: [
            ThemeOption(
              mode: ThemeMode.system,
              title: "System Default",
              subtitle: "Matches your device settings.",
              icon: Icons.brightness_auto_rounded,
              isSelected: currentMode == ThemeMode.system,
              onTap: () => apiService.setThemeMode(ThemeMode.system),
            ),
            const SizedBox(height: 12),
            ThemeOption(
              mode: ThemeMode.light,
              title: "Light Mode",
              subtitle: "Classic bright experience.",
              icon: Icons.wb_sunny_outlined,
              isSelected: currentMode == ThemeMode.light,
              onTap: () => apiService.setThemeMode(ThemeMode.light),
            ),
            const SizedBox(height: 12),
            ThemeOption(
              mode: ThemeMode.dark,
              title: "Premium Midnight",
              subtitle: "Elegant charcoal & gold theme.",
              icon: Icons.nightlight_round_outlined,
              isSelected: currentMode == ThemeMode.dark,
              onTap: () => apiService.setThemeMode(ThemeMode.dark),
            ),
          ],
        );
      },
    );
  }
}

class ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeOption({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap();
        HapticFeedback.mediumImpact();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : context.appBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.appBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? context.appPrimary : context.appTextMuted,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? context.appPrimary : context.appTextMain,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onUpdate;

  const ProfileInfoForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.isLoading,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileTextField(label: "Full Name", controller: nameController),
        const SizedBox(height: 16),
        ProfileTextField(
          label: "Email Address",
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onUpdate,
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
}

class UpdatePasswordForm extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onUpdate;

  const UpdatePasswordForm({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileTextField(
          label: "Current Password",
          controller: currentPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        ProfileTextField(
          label: "New Password",
          controller: newPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        ProfileTextField(
          label: "Confirm Password",
          controller: confirmPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onUpdate,
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
}

class DeleteAccountSection extends StatelessWidget {
  final VoidCallback onDelete;

  const DeleteAccountSection({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onDelete,
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
}

class ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: context.appTextMain,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.appBackground,
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
}
