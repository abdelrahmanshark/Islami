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
}

class Reciters {
  Reciters({this.id, this.name, this.server});

  Reciters.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    final moshafList = json['moshaf'];
    if (moshafList is List && moshafList.isNotEmpty) {
      server = moshafList.first['server'];
    }
  }

  int? id;
  String? name;
  String? server;
}
