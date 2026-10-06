import 'package:islami/models/azkar_response.dart';

/// Contract for loading the azkar and duaa categories.
abstract class AzkarRepository {
  Future<AzkarResponse> getAzkar();
}
