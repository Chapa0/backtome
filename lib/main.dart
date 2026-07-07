import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/core/firebase/firebase_options.dart';
import 'package:flutter_backtome/core/router/app_router.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/app_updates/presentation/widgets/app_update_gate.dart';
import 'package:flutter_backtome/features/auth/data/services/session_service.dart';
import 'package:flutter_backtome/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/user_home_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_backtome/shared/utils/mapbox_config.dart';
import 'package:flutter_backtome/shared/utils/local_bootstrap_secrets_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
  }

  await setupLocator();

  final token = await LocalBootstrapSecretsService.loadMapboxToken();
  MapboxConfig.configure(accessToken: token);
  mb.MapboxOptions.setAccessToken(token);

  await LocalBootstrapSecretsService.seedSecureStorageFromLocalAsset(
    locator<FlutterSecureStorage>(),
  );
  final appUpdateService = locator<AppUpdateService>();
  await appUpdateService.initialize();

  final authState = AuthState();
  final restoredSession = await locator<SessionService>().restoreSession();
  final restoredUser = restoredSession.user;
  if (restoredUser != null) {
    authState.setUser(restoredUser);
  }

  runApp(
    BackToMeApp(
      authState: authState,
      appUpdateService: appUpdateService,
    ),
  );
}

class BackToMeApp extends StatelessWidget {
  final AuthState authState;
  final AppUpdateService appUpdateService;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  BackToMeApp({
    super.key,
    required this.authState,
    required this.appUpdateService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: authState),
        ChangeNotifierProvider<AppUpdateService>.value(
          value: appUpdateService,
        ),
      ],
      child: AppUpdateGate(
        navigatorKey: _navigatorKey,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Back To Me',
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.onGenerateRoute,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF1B396A),
            scaffoldBackgroundColor: const Color(0xFFE1EDFF),
          ),
          home: const _RootPage(),
        ),
      ),
    );
  }
}

class _RootPage extends StatelessWidget {
  const _RootPage();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;

    if (user == null) {
      return PageLogin();
    }

    return PageAppGeneral();
  }
}
