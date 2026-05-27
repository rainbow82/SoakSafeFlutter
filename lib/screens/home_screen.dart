import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';
import 'package:soaksafe/data/user_repository.dart';
import 'package:soaksafe/widgets/frosted_card.dart';
import 'package:soaksafe/widgets/pool_background.dart';
import 'package:soaksafe/widgets/soaksafe_buttons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _biometricEnabled = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _maybeBiometricSignIn();
  }

  Future<void> _maybeBiometricSignIn() async {
    final app = context.read<AppState>();
    final enrollment = await app.sessionService.biometricEnrollment();
    if (enrollment == null || !mounted) return;
    setState(() => _biometricEnabled = true);
    final ok = await app.biometricService.authenticate(
      reason: 'Sign in to SoakSafe',
    );
    if (ok && mounted) {
      await _completeLogin(enrollment.userId, enrollment.username);
    }
  }

  Future<void> _completeLogin(int userId, String username) async {
    final app = context.read<AppState>();
    await app.setSession(userId, username);
    if (mounted) context.go('/maintenance');
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final repo = context.read<UserRepository>();
    final app = context.read<AppState>();
    final result = await repo.tryLogin(_username.text, _password.text);
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case LoginResult.emptyFields:
        _snack(AppStrings.errorLoginEmpty);
      case LoginResult.invalidCredentials:
        _snack(AppStrings.errorInvalidCredentials);
      case LoginResult.success:
        final user = await repo.userByUsername(_username.text.trim());
        if (user == null) return;
        if (_biometricEnabled) {
          await app.sessionService.saveBiometricEnrollment(
            userId: user.id,
            username: user.username,
          );
        }
        await _completeLogin(user.id, user.username);
        _snack(AppStrings.signedInWelcome);
    }
  }

  Future<void> _biometricSignIn() async {
    final app = context.read<AppState>();
    final enrollment = await app.sessionService.biometricEnrollment();
    if (enrollment == null) {
      _snack('Sign in with password first to enable fingerprint.');
      return;
    }
    final ok = await app.biometricService.authenticate(
      reason: 'Sign in to SoakSafe',
    );
    if (ok) await _completeLogin(enrollment.userId, enrollment.username);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PoolBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: SoakSafeColors.homeFormOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.homeSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: SoakSafeColors.homeFormOnSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use biometrics to sign in'),
                    value: _biometricEnabled,
                    activeThumbColor: SoakSafeColors.saveButton,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                  OutlinedPrimaryButton(
                    label: 'Sign in with biometrics',
                    icon: Icons.fingerprint,
                    onPressed: _biometricSignIn,
                  ),
                  const SizedBox(height: 24),
                  SaveButton(
                    label: AppStrings.signIn,
                    onPressed: _loading ? null : _signIn,
                  ),
                  const SizedBox(height: 12),
                  OutlinedPrimaryButton(
                    label: AppStrings.createAccount,
                    onPressed: () async {
                      final created = await context.push<bool>('/create-account');
                      if (created == true && mounted) {
                        _snack(AppStrings.accountCreated);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
