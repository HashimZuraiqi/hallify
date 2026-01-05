import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../auth/login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _newProfileImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _nameController.text = authProvider.user!.name;
      _phoneController.text = authProvider.user!.phone ?? '';
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isSaving = true);

    try {
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImagePath: _newProfileImagePath,
      );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _newProfileImagePath = null;
      });
      Helpers.showSuccessSnackbar(context, 'Profile updated successfully');
    } catch (e) {
      Helpers.showErrorSnackbar(context, 'Failed to update profile');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            )
          else
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _newProfileImagePath = null;
                });
                _loadUserData();
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(
              child: Text('Please login to view profile'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      if (_isEditing)
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement image picker
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: user.profileImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: user.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const ShimmerLoading(
                                        width: 120,
                                        height: 120,
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.primaryColor,
                                    ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: user.profileImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: user.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const ShimmerLoading(
                                      width: 120,
                                      height: 120,
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.primaryColor,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                if (!_isEditing)
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                const SizedBox(height: 4),
                // Email
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Edit Form
                if (_isEditing) ...[
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                      isLoading: _isSaving,
                    ),
                  ),
                ] else ...[
                  // Profile Info Cards
                  _ProfileInfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: user.email,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: user.phone ?? 'Not set',
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Member Since',
                    value: Helpers.formatDate(user.createdAt),
                  ),
                ],
                const SizedBox(height: 32),
                // Menu Options
                if (!_isEditing) ...[
                  _MenuOption(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      // Navigate to notifications settings
                    },
                  ),
                  _MenuOption(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      // Navigate to help
                    },
                  ),
                  _MenuOption(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      // Navigate to privacy policy
                    },
                  ),
                  _MenuOption(
                    icon: Icons.info_outline,
                    title: 'About Hallify',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Hallify',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2024 Hallify. All rights reserved.',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _showLogoutDialog,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _MenuOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: iconColor ?? Colors.grey[400],
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
