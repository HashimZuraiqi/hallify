import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../customer/customer_home_screen.dart';
import '../organizer/organizer_home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigate based on role
      Widget nextScreen;
      if (authProvider.isOrganizer) {
        nextScreen = const OrganizerHomeScreen();
      } else {
        nextScreen = const CustomerHomeScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.errorMessage ?? 'Login failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 20),
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.validatePassword,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16),
                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return GradientButton(
                      text: 'Sign In',
                      onPressed: _login,
                      isLoading: auth.isLoading,
                      width: double.infinity,
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 32),
                // Sign Up Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
