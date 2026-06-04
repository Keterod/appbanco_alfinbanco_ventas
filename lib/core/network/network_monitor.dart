import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream que emite true cuando hay red, false cuando no hay.
final networkStatusProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any(
      (r) => r != ConnectivityResult.none,
    ),
  );
});

/// Provider síncrono del estado actual de red.
/// Usar este en los Repositories para decidir si ir a Supabase o SQLite.
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(networkStatusProvider);
  return status.maybeWhen(
    data: (online) => online,
    orElse: () => false,
  );
});
