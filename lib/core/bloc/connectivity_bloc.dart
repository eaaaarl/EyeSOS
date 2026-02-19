import 'dart:async';
import 'package:eyesos/core/bloc/connectivity_event.dart';
import 'package:eyesos/core/bloc/connectivity_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityStatus> {
  StreamSubscription<InternetStatus>? _subscription;
  Timer? _disconnectTimer;
  Timer? _retryTimer;
  bool _wasEverDisconnected = false;

  // Facebook-like timing
  static const Duration _disconnectDelay = Duration(seconds: 3);
  static const Duration _retryInterval = Duration(seconds: 5);

  ConnectivityBloc() : super(ConnectivityStatus.connected) {
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<CheckConnectivity>(_onCheckConnectivity);
    on<RetryConnection>(_onRetryConnection);

    _subscription = InternetConnection().onStatusChange.listen(
      (status) => add(ConnectivityChanged(status)),
      onError: (_) => add(ConnectivityChanged(InternetStatus.disconnected)),
    );
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityStatus> emit,
  ) {
    final isConnected = event.status == InternetStatus.connected;

    if (isConnected) {
      _disconnectTimer?.cancel();
      _retryTimer?.cancel();

      if (_wasEverDisconnected && state == ConnectivityStatus.disconnected) {
        emit(ConnectivityStatus.connected);
        _wasEverDisconnected = false;
      }
      return;
    }

    // Cancel previous timer and start a new debounce
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(_disconnectDelay, () {
      if (!isClosed) {
        _wasEverDisconnected = true;
        // Use CheckConnectivity to verify before emitting disconnected
        add(CheckConnectivity());
      }
    });
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityStatus> emit,
  ) async {
    final hasConnection = await InternetConnection().hasInternetAccess;

    if (hasConnection) {
      _retryTimer?.cancel();
      if (state == ConnectivityStatus.disconnected) {
        _wasEverDisconnected = false;
        emit(ConnectivityStatus.connected);
      }
    } else {
      if (state != ConnectivityStatus.disconnected) {
        _wasEverDisconnected = true;
        emit(ConnectivityStatus.disconnected);
      }
      _startRetryTimer();
    }
  }

  Future<void> _onRetryConnection(
    RetryConnection event,
    Emitter<ConnectivityStatus> emit,
  ) async {
    emit(ConnectivityStatus.checking);

    final hasConnection = await InternetConnection().hasInternetAccess;

    if (hasConnection) {
      _retryTimer?.cancel();
      _wasEverDisconnected = false;
      emit(ConnectivityStatus.connected);
    } else {
      emit(ConnectivityStatus.disconnected);
      _startRetryTimer();
    }
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      if (!isClosed) add(CheckConnectivity());
    });
  }

  @override
  Future<void> close() {
    _disconnectTimer?.cancel();
    _retryTimer?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
