import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/db_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'core/app_theme.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SupabaseService.initialize();
  await DBService.instance.database;
  if (SupabaseService.isConfigured) {
    try {
      await SyncService.instance.triggerBackgroundSync();
    } catch (_) {
      // Keep startup resilient; queued jobs can retry later.
    }
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _backgroundSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (SupabaseService.isConfigured) {
      _backgroundSyncTimer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => SyncService.instance.triggerBackgroundSync(),
      );
    }
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && SupabaseService.isConfigured) {
      SyncService.instance.triggerBackgroundSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
