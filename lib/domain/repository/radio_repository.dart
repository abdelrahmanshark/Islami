import 'package:islami/ui/home/tabs/radio_screen/models/radio_response.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/reciters_response.dart';

abstract class RadioRepository {
  Future<List<Radios>> getRadios();

  Future<List<Reciters>> getReciters();
}
