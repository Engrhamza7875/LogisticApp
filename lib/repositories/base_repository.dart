import 'dart:async';
import 'package:sabcargo/services/logger_service.dart';

abstract class BaseRepository {
  /// Standard wrapper for API calls with logging and error handling
  Future<T> safeCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      appLogger.e('Repository Error: $e');
      rethrow;
    }
  }
}
