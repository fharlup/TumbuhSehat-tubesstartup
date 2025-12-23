import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;
// import 'package:mobile_tumbuh_sehat_v2/core/utils/debug_utils.dart';
import 'core/bloc/bloc_observer.dart';
import 'core/database/database_helper.dart';
import 'core/network/network_info.dart';
import 'core/services/notification_service.dart';
import 'core/theme/text_scale_wrapper.dart';
import 'core/theme/ts_color.dart';
import 'injection_container.dart' as di;
import 'presentation/cubit/beranda/beranda_cubit.dart';
import 'presentation/cubit/login/login_cubit.dart';
import 'presentation/cubit/onboarding/onboarding_cubit.dart';
import 'presentation/cubit/scan/scan_cubit.dart';
import 'presentation/cubit/splash/splash_cubit.dart';

import 'presentation/screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // await clearTumbuhSehatPreferencesOnDebug();
  // await deleteDatabaseOnDebug();
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;   
  tz.initializeTimeZones();
  await NotificationService.instance.init(navigatorKey);
  await di.init();
  await initializeDateFormatting('id_ID', null);
  NetworkInfoImpl.setForceOffline(true);
  Bloc.observer = SimpleBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<SplashCubit>()),
        BlocProvider(create: (_) => di.sl<OnboardingCubit>()),
        BlocProvider(create: (_) => di.sl<LoginCubit>()),
        BlocProvider(create: (_) => di.sl<ScanCubit>()),
        BlocProvider(create: (_) => di.sl<BerandaCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Tumbuh Sehat',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'OpenSans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: TSColor.mainTosca.primary,
          ),
          primarySwatch: Colors.lightGreen,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: TSColor.monochrome.white,
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TSColor.secondaryGreen.primary;
              }
              return TSColor.monochrome.white;
            }),
            checkColor: WidgetStateProperty.all(TSColor.monochrome.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        builder: (context, child) {
          return TextScaleWrapper(child: child ?? const SizedBox.shrink());
        },
        home: const SplashScreen(),
      ),
    );
  }
}
