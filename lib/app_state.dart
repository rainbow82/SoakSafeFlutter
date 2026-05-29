import 'package:flutter/foundation.dart';
import 'package:soaksafe/core/database/app_database.dart';
import 'package:soaksafe/core/services/biometric_service.dart';
import 'package:soaksafe/core/services/session_service.dart';
import 'package:soaksafe/data/maintenance_repository.dart';
import 'package:soaksafe/data/user_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.database,
    required this.userRepository,
    required this.maintenanceRepository,
    required this.sessionService,
    required this.biometricService,
  });

  final AppDatabase database;
  final UserRepository userRepository;
  final MaintenanceRepository maintenanceRepository;
  final SessionService sessionService;
  final BiometricService biometricService;

  int? currentUserId;
  String? currentUsername;

  Future<void> setSession(int userId, String username) async {
    currentUserId = userId;
    currentUsername = username;
    await sessionService.saveSession(userId: userId, displayName: username);
    notifyListeners();
  }

  Future<void> clearSession() async {
    currentUserId = null;
    currentUsername = null;
    await sessionService.clearSession();
    notifyListeners();
  }
}
