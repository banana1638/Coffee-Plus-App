import 'package:flutter/material.dart';
import 'coffee_loading_overlay.dart';
import '../services/api_service.dart';
import '../core/app_colors.dart';

class AuthModal extends StatefulWidget {
  final bool initialIsLogin;
  const AuthModal({super.key, this.initialIsLogin = true});

  static Future<void> show(BuildContext context, {bool initialIsLogin = true}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthModal(initialIsLogin: initialIsLogin),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  late bool isLogin;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialIsLogin;
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        (!isLogin && (name.isEmpty || confirmPassword.isEmpty))) {
      _showError("Please fill in all fields");
      return;
    }

    if (!isLogin && password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    if (isLogin) {
      result = await ApiService().login(
        email,
        password,
        rememberMe: _rememberMe,
      );
    } else {
      result = await ApiService().register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: confirmPassword,
      );
    }

    if (mounted) setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLogin ? "Login successful!" : "Registration successful!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh app state if needed
        ApiService().updateCartCount();
      }
    } else {
      _showError(
        result['message'] ?? (isLogin ? "Login failed" : "Registration failed"),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Icon(
              isLogin ? Icons.lock_outline_rounded : Icons.person_add_outlined,
              size: 60,
              color: context.appPrimary,
            ),
            const SizedBox(height: 20),
            Text(
              isLogin ? "WELCOME BACK" : "CREATE ACCOUNT",
              style: TextStyle(
                color: context.appPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),

            if (!isLogin) ...[
              _buildTextField(
                controller: _nameController,
                hintText: "Full Name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),
            ],

            _buildTextField(
              controller: _emailController,
              hintText: "Email Address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _passwordController,
              hintText: "Password",
              icon: Icons.lock_outline,
              obscureText: true,
            ),

            if (!isLogin) ...[
              const SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: "Confirm Password",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
            ],

            if (isLogin) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) =>
                          setState(() => _rememberMe = val ?? true),
                      activeColor: context.appPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Remember Me",
                    style: TextStyle(
                      color: context.appTextMain,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CoffeeLoadingIndicator(size: 20),
                      )
                    : Text(
                        isLogin ? "SIGN IN" : "SIGN UP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: context.appBackground,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin
                    ? "Don't have an account? Sign Up"
                    : "Already have an account? Sign In",
                style: TextStyle(
                  color: context.appPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: context.appTextMain),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: context.appTextMuted),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: context.appPrimary, width: 1),
        ),
      ),
    );
  }
}
