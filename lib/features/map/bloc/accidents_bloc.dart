import 'package:equatable/equatable.dart';
import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:eyesos/features/map/domain/usecases/fetch_accidents_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// EVENT

abstract class AccidentsEvent extends Equatable {
  const AccidentsEvent();

  @override
  List<Object?> get props => [];
}

class FetchAccidentsRequested extends AccidentsEvent {
  const FetchAccidentsRequested();

  @override
  List<Object?> get props => [];
}

// STATE

abstract class AccidentsState extends Equatable {
  const AccidentsState();

  @override
  List<Object?> get props => [];
}

class AccidentsInitial extends AccidentsState {}

class AccidentsLoading extends AccidentsState {}

class AccidentsLoaded extends AccidentsState {
  final List<AccidentEntity> accidents;

  const AccidentsLoaded({required this.accidents});

  @override
  List<Object?> get props => [accidents];
}

class AccidentsError extends AccidentsState {
  final String error;

  const AccidentsError({required this.error});

  @override
  List<Object?> get props => [error];
}

class AccidentsBloc extends Bloc<AccidentsEvent, AccidentsState> {
  final FetchAccidentsUsecase _fetchAccidentsUsecase;

  AccidentsBloc({required FetchAccidentsUsecase fetchAccidentsUsecase})
    : _fetchAccidentsUsecase = fetchAccidentsUsecase,
      super(AccidentsInitial()) {
    on<FetchAccidentsRequested>((event, emit) async {
      emit(AccidentsLoading());
      try {
        final accidents = await _fetchAccidentsUsecase();
        emit(AccidentsLoaded(accidents: accidents));
      } catch (e) {
        emit(AccidentsError(error: e.toString()));
      }
    });
  }
}
