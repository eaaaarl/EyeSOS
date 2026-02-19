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
import 'package:eyesos/features/auth/presentation/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/presentation/bloc/session_state.dart';
import 'package:eyesos/features/auth/presentation/bloc/signin_bloc.dart';
import 'package:eyesos/features/auth/presentation/bloc/signup_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accident_report_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_report_load_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/bloc/location/location_bloc.dart';
import 'package:eyesos/features/root/bloc/map/map_bloc.dart';
import 'package:eyesos/features/root/repository/accident_report_repository.dart';
import 'package:eyesos/features/root/bloc/road_risk/road_risk_bloc.dart';
import 'package:eyesos/features/root/bloc/road_risk/road_risk_event.dart';
import 'package:eyesos/features/root/repository/road_risk_repository.dart';
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
        RepositoryProvider(create: (context) => AccidentReportRepository()),
        RepositoryProvider(create: (context) => RoadRiskRepository()),
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
            create: (context) =>
                AccidentReportBloc(context.read<AccidentReportRepository>()),
          ),
          BlocProvider(
            create: (context) {
              final currentUser = context.read<SessionBloc>().state;
              String userId = '';
              if (currentUser is AuthAuthenticated) {
                userId = currentUser.userId;
              }
              return AccidentsReportLoadBloc(
                context.read<AccidentReportRepository>(),
              )..add(LoadRecentsReports(userId: userId));
            },
          ),
          BlocProvider(
            create: (context) =>
                RoadRiskBloc(repository: context.read<RoadRiskRepository>())
                  ..add(const FetchRoadRiskRequested()),
          ),
          BlocProvider(create: (context) => MapBloc()),
        ],
        child: const MyApp(),
      ),
    );
  }
}
