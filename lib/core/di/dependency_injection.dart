import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../services/local_storage_service.dart';
import '../services/socket_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/get_chat_list_usecase.dart';
import '../../features/chat/domain/usecases/get_chat_messages_usecase.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';
import '../../features/chat/presentation/bloc/chat_list_bloc.dart';
import '../../features/chat/presentation/bloc/chat_detail_bloc.dart';
import '../../features/auth/presentation/cubit/login_form_cubit.dart';
import '../../features/chat/presentation/cubit/chat_detail_ui_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Core services
  getIt.registerSingleton<ApiClient>(ApiClient());
  getIt.registerSingleton<SocketService>(SocketService());
  
  final localStorageService = LocalStorageService();
  await localStorageService.init();
  getIt.registerSingleton<LocalStorageService>(localStorageService);

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      localStorageService: getIt<LocalStorageService>(),
    ),
  );

  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      socketService: getIt<SocketService>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => LoginUsecase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUsecase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetChatListUsecase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => GetChatMessagesUsecase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SendMessageUsecase(getIt<ChatRepository>()));

  // Blocs
  getIt.registerSingleton(AuthBloc(
    loginUsecase: getIt<LoginUsecase>(),
    logoutUsecase: getIt<LogoutUsecase>(),
    localStorageService: getIt<LocalStorageService>(),
  ));

  getIt.registerFactory(() => ChatListBloc(
    getChatListUsecase: getIt<GetChatListUsecase>(),
  ));

  getIt.registerFactory(() => ChatDetailBloc(
    getChatMessagesUsecase: getIt<GetChatMessagesUsecase>(),
    sendMessageUsecase: getIt<SendMessageUsecase>(),
    socketService: getIt<SocketService>(),
  ));

  // Cubits
  getIt.registerFactory(() => LoginFormCubit());
  getIt.registerFactory(() => ChatDetailUICubit());
}