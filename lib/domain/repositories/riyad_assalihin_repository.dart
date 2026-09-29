import 'package:islami/models/riyad_assalihin.dart';

/// Contract for loading the Riyad Assalihin chapters and hadiths.
abstract class RiyadAssalihinRepository {
  Future<RiyadAssalihinModel> getRiyadAssalihin();
}
