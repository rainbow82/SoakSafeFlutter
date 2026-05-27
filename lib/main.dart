import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/database/app_database.dart';
import 'package:soaksafe/core/services/biometric_service.dart';
import 'package:soaksafe/core/services/session_service.dart';
import 'package:soaksafe/core/theme/soaksafe_theme.dart';
import 'package:soaksafe/data/maintenance_repository.dart';
import 'package:soaksafe/data/user_repository.dart';
import 'package:soaksafe/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docsDir = await getApplicationDocumentsDirectory();
  final database = await AppDatabase.open(docsDir.path);
  final userRepository = UserRepository(database);
  final maintenanceRepository = MaintenanceRepository(database);
  final sessionService = SessionService();
  final biometricService = BiometricService(LocalAuthentication());
  final appState = AppState(
    database: database,
    userRepository: userRepository,
    maintenanceRepository: maintenanceRepository,
    sessionService: sessionService,
    biometricService: biometricService,
  );
  final sessionUserId = await sessionService.lastUserId();
  final sessionUsername = await sessionService.lastDisplayName();
  if (sessionUserId != null && sessionUsername != null) {
    appState.currentUserId = sessionUserId;
    appState.currentUsername = sessionUsername;
  }
  runApp(SoakSafeApp(appState: appState));
}

class SoakSafeApp extends StatelessWidget {
  const SoakSafeApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        Provider.value(value: appState.userRepository),
        Provider.value(value: appState.maintenanceRepository),
        Provider.value(value: appState.sessionService),
        Provider.value(value: appState.biometricService),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        theme: buildSoakSafeTheme(),
        routerConfig: createRouter(appState),
      ),
    );
  }
}
