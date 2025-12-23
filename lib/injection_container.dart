import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/network/network_info.dart';
import 'core/services/notification_service.dart';
import 'core/utils/constants.dart';
import 'core/database/database_helper.dart';

// --- DATA SOURCES ---
import 'data/datasources/local/food_local_data_source.dart';
import 'data/datasources/local/onboarding_local_data_source.dart';
import 'data/datasources/remote/analysis_remote_datasource.dart';
import 'data/datasources/remote/food_remote_data_source.dart';
import 'data/datasources/remote/onboarding_remote_data_source.dart';

// --- REPOSITORIES ---
// Pastikan ini mengarah ke file repository Gemini yang baru kamu buat
import 'data/repositories/chatbot_repository_impl.dart'; 
import 'data/repositories/food_repository_impl.dart';
import 'data/repositories/nutrition_repository_impl.dart';
import 'data/repositories/onboarding_repository_impl.dart';
import 'data/repositories/recommendation_repository_impl.dart';

// --- DOMAIN REPOSITORIES ---
import 'domain/repositories/chatbot_repository.dart';
import 'domain/repositories/food_repository.dart';
import 'domain/repositories/nutrition_repository.dart';
import 'domain/repositories/onboarding_repository.dart';
import 'domain/repositories/recommendation_repository.dart';

// --- CUBITS ---
import 'presentation/cubit/beranda/beranda_cubit.dart';
import 'presentation/cubit/calory_history/calory_history_cubit.dart';
import 'presentation/cubit/chatbot/chatbot_cubit.dart';
import 'presentation/cubit/daily_detail/daily_detail_cubit.dart';
import 'presentation/cubit/food_prediction/food_prediction_cubit.dart';
import 'presentation/cubit/login/login_cubit.dart';
import 'presentation/cubit/meal_analysis/meal_analysis_cubit.dart';
import 'presentation/cubit/onboarding/onboarding_cubit.dart';
import 'presentation/cubit/profile/profile_cubit.dart';
import 'presentation/cubit/recommendation/recommendation_cubit.dart';
import 'presentation/cubit/scan/scan_cubit.dart';
import 'presentation/cubit/scan_analysis/scan_analysis_cubit.dart';
import 'presentation/cubit/splash/splash_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ================= EXTERNAL =================
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  sl.registerLazySingleton(() {
    final options = BaseOptions(
      baseUrl: AppConstants.BASE_URL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    );
    return Dio(options);
  });
  
  sl.registerLazySingleton(() => Connectivity());

  // ================= CORE =================
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl(), sl()));
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  // ================= DATA SOURCES =================
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<FoodRemoteDataSource>(
    () => FoodRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<FoodLocalDataSource>(
    () => FoodLocalDataSourceImpl(dbHelper: sl(), sharedPreferences: sl()),
  );
  sl.registerLazySingleton<AnalysisRemoteDataSource>(
    () => AnalysisRemoteDataSourceImpl(client: sl()),
  );
  
  // NOTE: ChatbotRemoteDataSource dihapus karena Gemini SDK menangani koneksi sendiri.

  // ================= REPOSITORIES =================
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<FoodRepository>(
    () => FoodRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<NutritionRepository>(
    () => NutritionRepositoryImpl(
      dbHelper: sl(),
      onboardingRepository: sl(),
      foodLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<RecommendationRepository>(
    () => RecommendationRepositoryImpl(
      dbHelper: sl(),
      nutritionRepository: sl(),
      localDataSource: sl(),
    ),
  );
  
  // --- PERUBAHAN UTAMA: REGISTER GEMINI REPOSITORY ---
  // Tidak perlu parameter remoteDataSource lagi
  sl.registerLazySingleton<ChatbotRepository>(
    () => ChatbotRepositoryImpl(),
  );

  // ================= SERVICE =================
  sl.registerLazySingleton(() => NotificationService.instance);

  // ================= FEATURES (CUBIT) =================
  sl.registerFactory(
    () => SplashCubit(onboardingRepository: sl(), sharedPreferences: sl()),
  );
  sl.registerFactory(() => OnboardingCubit(onboardingRepository: sl()));
  sl.registerFactory(
    () => LoginCubit(onboardingRepository: sl(), sharedPreferences: sl()),
  );
  sl.registerFactory(() => ScanCubit(onboardingRepository: sl()));
  sl.registerFactory(
    () => BerandaCubit(
      onboardingRepository: sl(),
      sharedPreferences: sl(),
      recommendationRepository: sl(),
      nutritionRepository: sl(),
    ),
  );
  sl.registerFactory(() => MealAnalysisCubit(foodRepository: sl()));
  sl.registerFactory(
    () => CaloryHistoryCubit(
      nutritionRepository: sl(),
      onboardingRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => DailyDetailCubit(nutritionRepository: sl(), onboardingRepository: sl()),
  );
  sl.registerFactory(
    () => RecommendationCubit(
      recommendationRepository: sl(),
      onboardingRepository: sl(),
    ),
  );
  sl.registerFactory(() => FoodPredictionCubit(remoteDataSource: sl()));
  sl.registerFactory(
    () => ProfileCubit(
      onboardingRepository: sl(),
      sharedPreferences: sl(),
      nutritionRepository: sl(),
      notificationService: sl(),
    ),
  );
  
  // ChatbotCubit tetap sama, dia otomatis mengambil ChatbotRepositoryImpl (Gemini)
  sl.registerFactory(() => ChatbotCubit(chatbotRepository: sl()));
  
  sl.registerFactory(
    () => ScanAnalysisCubit(nutritionRepository: sl(), foodRepository: sl()),
  );
}