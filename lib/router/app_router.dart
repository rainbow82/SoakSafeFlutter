import 'package:go_router/go_router.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/screens/create_account_screen.dart';
import 'package:soaksafe/screens/edit_report_screen.dart';
import 'package:soaksafe/screens/home_screen.dart';
import 'package:soaksafe/screens/maintenance_screen.dart';
import 'package:soaksafe/screens/profile_screen.dart';
import 'package:soaksafe/screens/report_screen.dart';

GoRouter createRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    redirect: (context, state) {
      final loggedIn = appState.currentUserId != null;
      final onHome = state.matchedLocation == '/';
      final onCreate = state.matchedLocation == '/create-account';
      if (!loggedIn && !onHome && !onCreate) return '/';
      if (loggedIn && onHome) return '/maintenance';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/create-account', builder: (_, __) => const CreateAccountScreen()),
      GoRoute(path: '/maintenance', builder: (_, __) => const MaintenanceScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/report',
        builder: (context, state) {
          final export = state.uri.queryParameters['export'] == '1';
          return ReportScreen(exportOnOpen: export);
        },
      ),
      GoRoute(
        path: '/report/:eventId/edit',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['eventId']!);
          return EditReportScreen(eventId: id);
        },
      ),
    ],
  );
}
