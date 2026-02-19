import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final InternetStatus status;
  ConnectivityChanged(this.status);
}

class CheckConnectivity extends ConnectivityEvent {}

class RetryConnection extends ConnectivityEvent {}
