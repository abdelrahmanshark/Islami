
class RecitersResponse {
  RecitersResponse({this.reciters});

  RecitersResponse.fromJson(dynamic json) {
    if (json['reciters'] != null) {
      reciters = [];
      json['reciters'].forEach((v) {
        reciters?.add(Reciters.fromJson(v));
      });
    }
  }

  List<Reciters>? reciters;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (reciters != null) {
      map['reciters'] = reciters?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Reciters {
  Reciters({this.id, this.name, this.letter, this.date, this.moshaf});

  Reciters.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    letter = json['letter'];
    date = json['date'];
    if (json['moshaf'] != null) {
      moshaf = [];
      json['moshaf'].forEach((v) {
        moshaf?.add(Moshaf.fromJson(v));
      });
    }
  }

  int? id;
  String? name;
  String? letter;
  String? date;
  List<Moshaf>? moshaf;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['letter'] = letter;
    map['date'] = date;
    if (moshaf != null) {
      map['moshaf'] = moshaf?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}


class Moshaf {
  Moshaf({
    this.id,
    this.name,
    this.rewayaId,
    this.server,
    this.surahTotal,
    this.moshafType,
    this.surahList,
  });

  Moshaf.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    rewayaId = json['rewaya_id'];
    server = json['server'];
    surahTotal = json['surah_total'];
    moshafType = json['moshaf_type'];
    surahList = json['surah_list'];
  }

  int? id;
  String? name;
  int? rewayaId;
  String? server;
  int? surahTotal;
  int? moshafType;
  String? surahList;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['rewaya_id'] = rewayaId;
    map['server'] = server;
    map['surah_total'] = surahTotal;
    map['moshaf_type'] = moshafType;
    map['surah_list'] = surahList;
    return map;
  }
}
