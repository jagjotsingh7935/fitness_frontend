import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_token_store.dart';
import '../../features/auth/presentation/client_signup_page.dart';
import '../../features/auth/presentation/login_otp_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/client/presentation/client_shell_page.dart';
import '../../features/client/presentation/pages/client_exercises_page.dart';
import '../../features/client/presentation/pages/client_home_page.dart';
import '../../features/client/presentation/pages/client_plans_page.dart';
import '../../features/client/presentation/pages/client_profile_page.dart';
import '../../features/client/presentation/pages/client_videos_page.dart';
import '../../features/client/presentation/pages/workout_active_page.dart';
import '../../features/admin/presentation/admin_shell_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_trainers_page.dart';
import '../../features/admin/presentation/pages/admin_clients_page.dart';
import '../../features/admin/presentation/pages/admin_exercises_page.dart';
import '../../features/admin/presentation/pages/admin_workouts_page.dart';
import '../../features/admin/presentation/pages/admin_videos_page.dart';
import '../../features/admin/presentation/pages/admin_profile_page.dart';
import '../../features/trainer/presentation/trainer_shell_page.dart';
import '../../features/trainer/presentation/pages/trainer_clients_page.dart';
import '../../features/trainer/presentation/pages/trainer_dashboard_page.dart';
import '../../features/trainer/presentation/pages/trainer_exercise.dart';
import '../../features/trainer/presentation/pages/trainer_profile_page.dart';
import '../../features/trainer/presentation/pages/trainer_workout.dart';

class AppRouter {
  static const loginPath = '/login';
  static const adminLoginPath = '/login/admin';
  static const loginOtpPath = '$loginPath/otp';
  static const clientSignupPath = '$loginPath/signup';
  static const clientPath = '/client';
  static const adminPath = '/admin';
  static const trainerPath = '/trainer';

  static String _determineInitialLocation() {
    if (!GetIt.I.isRegistered<AuthTokenStore>()) {
      return loginPath;
    }
    final tokenStore = GetIt.I<AuthTokenStore>();
    if (!tokenStore.isAuthenticated) {
      return loginPath;
    }

    final lastLoc = tokenStore.lastLocation;
    if (lastLoc != null &&
        lastLoc.isNotEmpty &&
        lastLoc != '/' &&
        (lastLoc.startsWith(adminPath) ||
            lastLoc.startsWith(trainerPath) ||
            lastLoc.startsWith(clientPath))) {
      return lastLoc;
    }

    final user = tokenStore.user;
    if (user != null) {
      if (user.isAdmin) return adminPath;
      if (user.isTrainer) return trainerPath;
      return clientPath;
    }

    return clientPath;
  }

  static GoRouter? _instance;

  static GoRouter get router {
    _instance ??= _buildRouter();
    return _instance!;
  }

  static GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: _determineInitialLocation(),
      errorBuilder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0D1A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_rounded, color: Color(0xFFFF4B72), size: 54),
                  const SizedBox(height: 16),
                  const Text(
                    'Page Not Found',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Path: ${state.uri.path}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final tokenStore = GetIt.I.isRegistered<AuthTokenStore>()
                          ? GetIt.I<AuthTokenStore>()
                          : null;
                      if (tokenStore == null || !tokenStore.isAuthenticated) {
                        context.go(AppRouter.loginPath);
                      } else {
                        final user = tokenStore.user;
                        if (user != null && user.isAdmin) {
                          context.go(AppRouter.adminPath);
                        } else if (user != null && user.isTrainer) {
                          context.go(AppRouter.trainerPath);
                        } else {
                          context.go(AppRouter.clientPath);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B72),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      redirect: (context, state) {
        if (!GetIt.I.isRegistered<AuthTokenStore>()) return null;

        final tokenStore = GetIt.I<AuthTokenStore>();
        final isLoggingIn = state.matchedLocation.startsWith(loginPath);

        if (!tokenStore.isAuthenticated) {
          return isLoggingIn ? null : loginPath;
        }

        // Handle root / navigation
        if (state.matchedLocation == '/') {
          final user = tokenStore.user;
          if (user != null) {
            if (user.isAdmin) return adminPath;
            if (user.isTrainer) return trainerPath;
          }
          return clientPath;
        }

        // If authenticated and trying to navigate to login, redirect to active portal
        if (isLoggingIn) {
          final lastLoc = tokenStore.lastLocation;
          if (lastLoc != null &&
              lastLoc.isNotEmpty &&
              lastLoc != '/' &&
              !lastLoc.startsWith('/login')) {
            return lastLoc;
          }
          final user = tokenStore.user;
          if (user != null) {
            if (user.isAdmin) return adminPath;
            if (user.isTrainer) return trainerPath;
          }
          return clientPath;
        }

        // Save last location whenever navigating to a valid non-login route
        if (state.matchedLocation != '/') {
          tokenStore.saveLastLocation(state.matchedLocation);
        }

        return null;
      },

    routes: <RouteBase>[
      // Root route redirect
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final tokenStore = GetIt.I.isRegistered<AuthTokenStore>()
              ? GetIt.I<AuthTokenStore>()
              : null;
          if (tokenStore == null || !tokenStore.isAuthenticated) {
            return AppRouter.loginPath;
          }
          final user = tokenStore.user;
          if (user != null) {
            if (user.isAdmin) return AppRouter.adminPath;
            if (user.isTrainer) return AppRouter.trainerPath;
          }
          return AppRouter.clientPath;
        },
      ),

      // Trainer progress alias
      GoRoute(
        path: '/trainer/progress',
        redirect: (context, state) => '$trainerPath/clients',
      ),

      // Login routes
      GoRoute(
        path: loginPath,
        name: 'login',
        builder: (context, state) => const LoginPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'otp',
            name: 'login_otp',
            builder: (context, state) => const LoginOtpPage(),
          ),
          GoRoute(
            path: 'signup',
            name: 'client_signup',
            builder: (context, state) => const ClientSignupPage(),
          ),
          GoRoute(
            path: 'admin',
            name: 'admin_login',
            builder: (context, state) => const LoginPage(isAdminLogin: true),
          ),
        ],
      ),
      
      // Client Shell with branches
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ClientShellPage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: clientPath,
                name: 'client_home',
                builder: (context, state) => const ClientHomePage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'workout-active',
                    name: 'workout_active',
                    builder: (context, state) => const WorkoutActivePage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$clientPath/exercises',
                name: 'client_exercises',
                builder: (context, state) => const ClientExercisesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$clientPath/plans',
                name: 'client_plans',
                builder: (context, state) => const ClientPlansPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$clientPath/videos',
                name: 'client_videos',
                builder: (context, state) => const ClientVideosPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$clientPath/profile',
                name: 'client_profile',
                builder: (context, state) => const ClientProfilePage(),
              ),
            ],
          ),
        ],
      ),
      
      // Admin Shell with branches
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShellPage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: adminPath,
                name: 'admin_dashboard',
                builder: (context, state) => const AdminDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$adminPath/trainers',
                name: 'admin_trainers',
                builder: (context, state) => const AdminTrainersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$adminPath/clients',
                name: 'admin_clients',
                builder: (context, state) => const AdminClientsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$adminPath/exercises',
                name: 'admin_exercises',
                builder: (context, state) => const AdminExercisesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$adminPath/workouts',
                name: 'admin_workouts',
                builder: (context, state) => const AdminWorkoutsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$adminPath/videos',
                name: 'admin_videos',
                builder: (context, state) => const AdminVideosPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$adminPath/profile',
                name: 'admin_profile',
                builder: (context, state) => const AdminProfilePage(),
              ),
            ],
          ),
        ],
      ),
      
      // Trainer Shell with branches
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TrainerShellPage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: trainerPath,
                name: 'trainer_dashboard',
                builder: (context, state) => const TrainerDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$trainerPath/clients',
                name: 'trainer_clients',
                builder: (context, state) => const TrainerClientsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$trainerPath/exercises',
                name: 'trainer_exercises',
                builder: (context, state) => const TrainerExercisesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$trainerPath/workouts',
                name: 'trainer_workouts',
                builder: (context, state) => const TrainerWorkoutsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '$trainerPath/profile',
                name: 'trainer_profile',
                builder: (context, state) => const TrainerProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  }
}