import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fitness Metabolism',
      theme: AppTheme.dark(),
      routerConfig: AppRouter.router,
    );
  }
}
