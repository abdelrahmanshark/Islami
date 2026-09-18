import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';

/// Contract for loading prayer times.
abstract class TimeRepository {
  Future<TimeResponse> getTimeResponse();
}
