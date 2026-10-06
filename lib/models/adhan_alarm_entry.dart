/// One scheduled Adhan: when it fires and which prayer it belongs to.
class AdhanAlarmEntry {
  const AdhanAlarmEntry({
    required this.time,
    required this.prayerName,
  });

  final DateTime time;
  final String prayerName;

  /// JSON shape read by Android's AdhanScheduler.
  Map<String, dynamic> toJson() {
    return {
      'time': time.millisecondsSinceEpoch,
      'name': prayerName,
    };
  }
}
