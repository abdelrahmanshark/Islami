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
  Reciters({this.name, this.server});

  Reciters.fromJson(dynamic json) {
    name = json['name'];
    final moshafList = json['moshaf'];
    if (moshafList is List && moshafList.isNotEmpty) {
      server = moshafList.first['server'];
    }
  }

  String? name;
  String? server;
}
