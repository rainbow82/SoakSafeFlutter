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
  bool _biometricAvailable = false;
  bool _hasEnrollment = false;
  bool _suppressBiometricSwitchCallback = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initBiometricUi();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _initBiometricUi() async {
    final app = context.read<AppState>();
    final available = await app.biometricService.isAvailable();
    final enrollment = await app.sessionService.biometricEnrollment();
    if (!mounted) return;

    setState(() {
      _biometricAvailable = available;
      _hasEnrollment = enrollment != null;
      _suppressBiometricSwitchCallback = true;
      _biometricEnabled = enrollment != null;
      _suppressBiometricSwitchCallback = false;
      if (enrollment != null && _username.text.trim().isEmpty) {
        _username.text = enrollment.username;
      }
    });

    if (enrollment != null && available) {
      await _maybeOfferBiometricSignIn();
    }
  }

  Future<void> _maybeOfferBiometricSignIn() async {
    final app = context.read<AppState>();
    final enrollment = await app.sessionService.biometricEnrollment();
    if (enrollment == null || !mounted) return;

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
          if (mounted) setState(() => _hasEnrollment = true);
        }
        await _completeLogin(user.id, user.username);
        _snack(AppStrings.signedInWelcome);
    }
  }

  Future<void> _biometricSignIn() async {
    final app = context.read<AppState>();
    final repo = context.read<UserRepository>();
    final enrollment = await app.sessionService.biometricEnrollment();
    if (enrollment == null) {
      _snack(AppStrings.biometricEnableRequiresPassword);
      return;
    }

    final ok = await app.biometricService.authenticate(
      reason: 'Sign in to SoakSafe',
    );
    if (!ok || !mounted) return;

    final user = await repo.userById(enrollment.userId);
    if (user == null) {
      await app.sessionService.clearBiometricEnrollment();
      if (!mounted) return;
      setState(() {
        _hasEnrollment = false;
        _suppressBiometricSwitchCallback = true;
        _biometricEnabled = false;
        _suppressBiometricSwitchCallback = false;
      });
      _snack(AppStrings.biometricAccountMissing);
      return;
    }

    await _completeLogin(user.id, user.username);
  }

  Future<void> _onBiometricSwitchChanged(bool value) async {
    if (_suppressBiometricSwitchCallback) return;

    if (!value) {
      await context.read<AppState>().sessionService.clearBiometricEnrollment();
      if (!mounted) return;
      setState(() {
        _hasEnrollment = false;
        _biometricEnabled = false;
      });
      _snack(AppStrings.biometricDisabled);
      return;
    }

    await _enableBiometricAfterPasswordCheck();
  }

  Future<void> _enableBiometricAfterPasswordCheck() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      _revertBiometricSwitch();
      _snack(AppStrings.biometricEnableRequiresPassword);
      return;
    }

    final repo = context.read<UserRepository>();
    final app = context.read<AppState>();
    final result = await repo.tryLogin(username, password);
    if (result != LoginResult.success) {
      _revertBiometricSwitch();
      _snack(
        result == LoginResult.emptyFields
            ? AppStrings.errorLoginEmpty
            : AppStrings.errorInvalidCredentials,
      );
      return;
    }

    final user = await repo.userByUsername(username);
    if (user == null) {
      _revertBiometricSwitch();
      return;
    }

    final ok = await app.biometricService.authenticate(
      reason: 'Confirm fingerprint sign-in for SoakSafe',
    );
    if (!ok) {
      _revertBiometricSwitch();
      return;
    }

    await app.sessionService.saveBiometricEnrollment(
      userId: user.id,
      username: user.username,
    );
    if (!mounted) return;
    setState(() {
      _hasEnrollment = true;
      _suppressBiometricSwitchCallback = true;
      _biometricEnabled = true;
      _suppressBiometricSwitchCallback = false;
    });
    _snack(AppStrings.biometricEnabled);
  }

  void _revertBiometricSwitch() {
    setState(() {
      _suppressBiometricSwitchCallback = true;
      _biometricEnabled = false;
      _suppressBiometricSwitchCallback = false;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final showBiometricControls = _biometricAvailable;
    final showBiometricButton = _biometricAvailable && _hasEnrollment;

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
                  if (showBiometricControls) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(AppStrings.biometricEnableLabel),
                      value: _biometricEnabled,
                      activeThumbColor: SoakSafeColors.saveButton,
                      onChanged: _onBiometricSwitchChanged,
                    ),
                    if (showBiometricButton)
                      OutlinedPrimaryButton(
                        label: AppStrings.biometricSignIn,
                        icon: Icons.fingerprint,
                        onPressed: _biometricSignIn,
                      ),
                    const SizedBox(height: 24),
                  ],
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
