import 'package:fitness_metabolism_app/features/admin/presentation/pages/admin_exercises_page.dart';
import 'package:fitness_metabolism_app/features/trainer/presentation/pages/trainer_exercise.dart';
import 'package:fitness_metabolism_app/features/trainer/presentation/pages/trainer_profile_page.dart';
import 'package:fitness_metabolism_app/features/trainer/presentation/pages/trainer_workout.dart';
import 'package:go_router/go_router.dart';

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
import '../../features/admin/presentation/pages/admin_diet_plans_page.dart';
import '../../features/admin/presentation/pages/admin_workouts_page.dart';
import '../../features/admin/presentation/pages/admin_videos_page.dart';
import '../../features/admin/presentation/pages/admin_profile_page.dart';
import '../../features/trainer/presentation/trainer_shell_page.dart';
import '../../features/trainer/presentation/pages/trainer_clients_page.dart';
import '../../features/trainer/presentation/pages/trainer_dashboard_page.dart';
import '../../features/trainer/presentation/pages/trainer_exercise.dart';
import '../../features/trainer/presentation/pages/trainer_workout.dart';

class AppRouter {
  static const loginPath = '/login';
  static const adminLoginPath = '/login/admin';
  static const loginOtpPath = '$loginPath/otp';
  static const clientSignupPath = '$loginPath/signup';
  static const clientPath = '/client';
  static const adminPath = '/admin';
  static const trainerPath = '/trainer';

  static GoRouter router = GoRouter(
    initialLocation: loginPath,
    routes: <RouteBase>[
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
          // StatefulShellBranch(
          //   routes: <RouteBase>[
          //     GoRoute(
          //       path: '$trainerPath/nutrition',
          //       name: 'trainer_nutrition',
          //       builder: (context, state) => const TrainerNutritionPage(),
          //     ),
          //   ],
          // ),
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