import 'package:islami/models/azkar_response.dart';

/// Contract for loading morning and evening azkar.
abstract class AzkarRepository {
  Future<AzkarResponse> getAzkar();
}
