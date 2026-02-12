import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

//EVENTS

abstract class ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final InternetStatus status;
  ConnectivityChanged(this.status);
}

class CheckConnectivity extends ConnectivityEvent {}

class RetryConnection extends ConnectivityEvent {}

//STATES

enum ConnectivityStatus { connected, disconnected, checking }

//BLOC

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityStatus> {
  StreamSubscription<InternetStatus>? _subscription;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  int _disconnectCount = 0;

  // Debounce settings - more lenient for better UX
  static const Duration _debounceDisconnect = Duration(
    seconds: 10,
  ); // Wait 10s before showing "disconnected"
  static const Duration _debounceConnect = Duration(
    seconds: 5,
  ); // Wait 5s before showing "connected"
  static const int _requiredDisconnectsBeforeAlert =
      1; // Need 1 disconnect signal before alerting

  // Retry settings
  static const Duration _retryInterval = Duration(
    seconds: 5,
  ); // Auto-retry every 5s when disconnected

  ConnectivityBloc() : super(ConnectivityStatus.connected) {
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<CheckConnectivity>(_onCheckConnectivity);
    on<RetryConnection>(_onRetryConnection);

    // Listen to internet status changes
    _subscription = InternetConnection().onStatusChange.listen(
      (status) => add(ConnectivityChanged(status)),
      onError: (_) => add(ConnectivityChanged(InternetStatus.disconnected)),
    );
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityStatus> emit,
  ) async {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    final isConnected = event.status == InternetStatus.connected;

    // If connection restored, reset everything
    if (isConnected) {
      _disconnectCount = 0;
      _retryTimer?.cancel();

      // Don't show "connected" if we were never disconnected
      if (state == ConnectivityStatus.connected) {
        return;
      }

      // Debounce the "connected" message to avoid flickering
      await Future.delayed(_debounceConnect);

      // Check if the emitter is still active before emitting
      if (!emit.isDone) {
        emit(ConnectivityStatus.connected);
      }
      return;
    }

    // Handle disconnection with retry logic
    _disconnectCount++;

    // Only show disconnected after multiple signals (more lenient)
    if (_disconnectCount < _requiredDisconnectsBeforeAlert) {
      return;
    }

    // Debounce the "disconnected" message
    await Future.delayed(_debounceDisconnect);

    // Check if the emitter is still active and we're still disconnected
    if (!emit.isDone && !isConnected) {
      emit(ConnectivityStatus.disconnected);
      _startRetryTimer();
    }
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (timer) {
      if (!isClosed) {
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
      _disconnectCount = 0;
      _retryTimer?.cancel();
      emit(ConnectivityStatus.connected);
    } else if (state != ConnectivityStatus.disconnected) {
      emit(ConnectivityStatus.disconnected);
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
      _disconnectCount = 0;
      _retryTimer?.cancel();
      emit(ConnectivityStatus.connected);
    } else {
      emit(ConnectivityStatus.disconnected);
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
