import 'package:islami/models/radio_response.dart';
import 'package:islami/models/reciters_response.dart';

/// Contract for loading radios and reciters.
abstract class RadioRepository {
  Future<List<Radios>> getRadios();

  Future<List<Reciters>> getReciters();
}
