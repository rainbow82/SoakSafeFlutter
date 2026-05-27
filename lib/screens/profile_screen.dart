import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/data/user_repository.dart';
import 'package:soaksafe/widgets/frosted_card.dart';
import 'package:soaksafe/widgets/pool_background.dart';
import 'package:soaksafe/widgets/soaksafe_buttons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _username = TextEditingController();
  final _poolSize = TextEditingController();
  bool _saltWater = false;
  bool _aboveGround = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    final userId = app.currentUserId;
    if (userId == null) return;
    final user = await context.read<UserRepository>().userById(userId);
    if (user == null || !mounted) return;
    setState(() {
      _username.text = user.username;
      _poolSize.text = user.poolSizeGallons.toString();
      _saltWater = user.poolSaltWater;
      _aboveGround = user.poolAboveGround;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final userId = app.currentUserId;
    if (userId == null) return;
    final size = int.tryParse(_poolSize.text.trim()) ?? 0;
    final (result, updated) = await context.read<UserRepository>().updateProfile(
          userId: userId,
          username: _username.text,
          poolSizeGallons: size,
          poolSaltWater: _saltWater,
          poolAboveGround: _aboveGround,
        );
    if (!mounted) return;
    if (result == UpdateProfileResult.success && updated != null) {
      await app.setSession(updated.id, updated.username);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSaved)),
      );
      context.pop();
    } else if (result == UpdateProfileResult.invalidPoolSize) {
      _snack(AppStrings.errorPoolSize);
    } else if (result == UpdateProfileResult.usernameTaken) {
      _snack(AppStrings.errorUsernameTaken);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: PoolBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      AppStrings.profileTitle,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FrostedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _username,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _poolSize,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.poolSizeLabel,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Installation', style: TextStyle(fontWeight: FontWeight.w600)),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text(AppStrings.poolAboveGround)),
                            ButtonSegment(value: false, label: Text(AppStrings.poolInGround)),
                          ],
                          selected: {_aboveGround},
                          onSelectionChanged: (s) => setState(() => _aboveGround = s.first),
                        ),
                        const SizedBox(height: 16),
                        const Text('Pool type', style: TextStyle(fontWeight: FontWeight.w600)),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text(AppStrings.poolTypeFresh)),
                            ButtonSegment(value: true, label: Text(AppStrings.poolTypeSalt)),
                          ],
                          selected: {_saltWater},
                          onSelectionChanged: (s) => setState(() => _saltWater = s.first),
                        ),
                        const SizedBox(height: 24),
                        SaveButton(label: AppStrings.saveProfile, onPressed: _save),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
