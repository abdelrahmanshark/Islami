class TimeResponse {
  int? code;
  String? status;
  PrayerData? data;

  TimeResponse.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    status = json['status'];

    if (json['data'] != null) {
      data = PrayerData.fromJson(json['data']);
    }
  }
}

class PrayerData {
  Timings? timings;
  DateInfo? date;

  PrayerData.fromJson(Map<String, dynamic> json) {
    if (json['timings'] != null) {
      timings = Timings.fromJson(json['timings']);
    }

    if (json['date'] != null) {
      date = DateInfo.fromJson(json['date']);
    }
  }
}

class Timings {
  String? fajr;
  String? sunrise;
  String? dhuhr;
  String? asr;
  String? sunset;
  String? maghrib;
  String? isha;
  String? imsak;
  String? midnight;
  String? firstThird;
  String? lastThird;

  Timings.fromJson(Map<String, dynamic> json) {
    fajr = json['Fajr'];
    sunrise = json['Sunrise'];
    dhuhr = json['Dhuhr'];
    asr = json['Asr'];
    sunset = json['Sunset'];
    maghrib = json['Maghrib'];
    isha = json['Isha'];
    imsak = json['Imsak'];
    midnight = json['Midnight'];
    firstThird = json['Firstthird'];
    lastThird = json['Lastthird'];
  }
}

class DateInfo {
  String? readable;
  String? timestamp;
  HijriDate? hijri;
  GregorianDate? gregorian;

  DateInfo.fromJson(Map<String, dynamic> json) {
    readable = json['readable'];
    timestamp = json['timestamp'];

    if (json['hijri'] != null) {
      hijri = HijriDate.fromJson(json['hijri']);
    }

    if (json['gregorian'] != null) {
      gregorian = GregorianDate.fromJson(json['gregorian']);
    }
  }
}

class GregorianDate {
  String? date;
  String? format;
  String? day;
  GregorianWeekday? weekday;
  GregorianMonth? month;
  String? year;
  GregorianDesignation? designation;
  bool? lunarSighting;

  GregorianDate.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    format = json['format'];
    day = json['day'];

    if (json['weekday'] != null) {
      weekday = GregorianWeekday.fromJson(json['weekday']);
    }

    if (json['month'] != null) {
      month = GregorianMonth.fromJson(json['month']);
    }

    year = json['year'];

    if (json['designation'] != null) {
      designation = GregorianDesignation.fromJson(json['designation']);
    }

    lunarSighting = json['lunarSighting'];
  }
}

class HijriDate {
  String? date;
  String? format;
  String? day;
  HijriWeekday? weekday;
  HijriMonth? month;
  String? year;
  HijriDesignation? designation;
  List<String>? holidays;
  List<String>? adjustedHolidays;
  String? method;

  HijriDate.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    format = json['format'];
    day = json['day'];

    if (json['weekday'] != null) {
      weekday = HijriWeekday.fromJson(json['weekday']);
    }

    if (json['month'] != null) {
      month = HijriMonth.fromJson(json['month']);
    }

    year = json['year'];

    if (json['designation'] != null) {
      designation = HijriDesignation.fromJson(json['designation']);
    }

    holidays = json['holidays'] != null
        ? List<String>.from(json['holidays'])
        : [];

    adjustedHolidays = json['adjustedHolidays'] != null
        ? List<String>.from(json['adjustedHolidays'])
        : [];

    method = json['method'];
  }
}

class GregorianWeekday {
  String? en;

  GregorianWeekday.fromJson(Map<String, dynamic> json) {
    en = json['en'];
  }
}

class HijriWeekday {
  String? en;
  String? ar;

  HijriWeekday.fromJson(Map<String, dynamic> json) {
    en = json['en'];
    ar = json['ar'];
  }
}

class GregorianMonth {
  int? number;
  String? en;

  GregorianMonth.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    en = json['en'];
  }
}

class HijriMonth {
  int? number;
  String? en;
  String? ar;
  int? days;

  HijriMonth.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    en = json['en'];
    ar = json['ar'];
    days = json['days'];
  }
}

class GregorianDesignation {
  String? abbreviated;
  String? expanded;

  GregorianDesignation.fromJson(Map<String, dynamic> json) {
    abbreviated = json['abbreviated'];
    expanded = json['expanded'];
  }
}

class HijriDesignation {
  String? abbreviated;
  String? expanded;

  HijriDesignation.fromJson(Map<String, dynamic> json) {
    abbreviated = json['abbreviated'];
    expanded = json['expanded'];
  }
}
