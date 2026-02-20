import 'package:eyesos/app.dart';
import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:eyesos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:eyesos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:eyesos/features/auth/domain/usecases/signin_usecase.dart';
import 'package:eyesos/features/auth/domain/usecases/signin_with_google_usecase.dart';
import 'package:eyesos/features/auth/domain/usecases/signup_usecase.dart';
import 'package:eyesos/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:eyesos/features/auth/domain/usecases/sign_out_google_usecase.dart';
import 'package:eyesos/features/auth/domain/usecases/has_phone_number_usecase.dart';
import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/auth/bloc/signin_bloc.dart';
import 'package:eyesos/features/auth/bloc/signup_bloc.dart';
import 'package:eyesos/features/home/bloc/accident_report_bloc.dart';
import 'package:eyesos/features/home/bloc/accidents_report_load_bloc.dart';
import 'package:eyesos/features/home/bloc/accidents_reports_load_event.dart';
import 'package:eyesos/features/home/domain/repositories/i_accident_repository.dart';
import 'package:eyesos/features/home/data/repositories/accident_repository_impl.dart';
import 'package:eyesos/features/home/data/datasources/accident_remote_datasource.dart';
import 'package:eyesos/features/home/domain/usecases/load_recent_reports_usecase.dart';
import 'package:eyesos/features/home/domain/usecases/send_report_accident_usecase.dart';
import 'package:eyesos/features/map/bloc/location_bloc.dart';
import 'package:eyesos/features/map/bloc/map_bloc.dart';
import 'package:eyesos/features/map/bloc/road_risk_bloc.dart';
import 'package:eyesos/features/map/bloc/road_risk_event.dart';
import 'package:eyesos/features/map/data/datasources/map_remote_datasource.dart';
import 'package:eyesos/features/map/data/repositories/map_repositories_impl.dart';
import 'package:eyesos/features/map/domain/repositories/i_map_repository.dart';
import 'package:eyesos/features/map/domain/usecases/fetch_roads_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAuthRepository>(
          create: (context) => AuthRepositoryImpl(AuthRemoteDatasource()),
        ),
        RepositoryProvider<IAccidentRepository>(
          create: (context) =>
              AccidentRepositoryImpl(AccidentRemoteDatasource()),
        ),
        RepositoryProvider<IMapRepository>(
          create: (context) => IMapRepositoryImpl(MapRemoteDatasource()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ConnectivityBloc()),
          BlocProvider(
            create: (context) {
              final repo = context.read<IAuthRepository>();
              return SessionBloc(
                signOutUsecase: SignOutUsecase(repo),
                signOutGoogleUsecase: SignOutGoogleUsecase(repo),
              );
            },
          ),
          BlocProvider(
            create: (context) {
              final repo = context.read<IAuthRepository>();
              return SignupBloc(signupUsecase: SignupUsecase(repo));
            },
          ),
          BlocProvider(
            create: (context) {
              final repo = context.read<IAuthRepository>();
              return SigninBloc(
                signInUsecase: SignInUsecase(repo),
                signInWithGoogleUsecase: SignInWithGoogleUsecase(repo),
                hasPhoneNumberUsecase: HasPhoneNumberUsecase(repo),
              );
            },
          ),
          BlocProvider(create: (context) => LocationBloc()),
          BlocProvider(
            create: (context) {
              final repo = context.read<IAccidentRepository>();
              return AccidentReportBloc(
                sendReportAccidentUseCase: SendReportAccidentUsecase(repo),
              );
            },
          ),
          BlocProvider(
            create: (context) {
              final currentUser = context.read<SessionBloc>().state;
              String userId = '';
              if (currentUser is AuthAuthenticated) {
                userId = currentUser.userId;
              }
              return AccidentsReportLoadBloc(
                loadRecentReportsUsecase: LoadRecentReportsUsecase(
                  repository: context.read<IAccidentRepository>(),
                ),
              )..add(LoadRecentReports(userId: userId));
            },
          ),
          BlocProvider(
            create: (context) {
              final repo = context.read<IMapRepository>();
              return RoadRiskBloc(fetchRoadsUseCase: FetchRoadsUseCase(repo))
                ..add(const FetchRoadRiskRequested());
            },
          ),
          BlocProvider(create: (context) => MapBloc()),
        ],
        child: const MyApp(),
      ),
    );
  }
}
