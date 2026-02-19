import 'package:eyesos/app.dart';
import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/auth/bloc/signin_bloc.dart';
import 'package:eyesos/features/auth/bloc/signup_bloc.dart';
import 'package:eyesos/features/auth/repository/auth_repository.dart';
import 'package:eyesos/features/root/bloc/accidents/accident_report_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_report_load_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/bloc/location/location_bloc.dart';
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
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => AccidentReportRepository()),
        RepositoryProvider(create: (context) => RoadRiskRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ConnectivityBloc()),
          BlocProvider(
            create: (context) => SessionBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => SignupBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => SigninBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                LocationBloc() /* ..add(FetchLocationRequested()) */,
          ),
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
        ],
        child: const MyApp(),
      ),
    );
  }
}
