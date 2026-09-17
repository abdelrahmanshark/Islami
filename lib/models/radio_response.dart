class RadioResponse {
  RadioResponse({this.radios});

  RadioResponse.fromJson(dynamic json) {
    if (json['radios'] != null) {
      radios = [];
      json['radios'].forEach((v) {
        radios?.add(Radios.fromJson(v));
      });
    }
  }

  List<Radios>? radios;
}

class Radios {
  Radios({this.name, this.url});

  Radios.fromJson(dynamic json) {
    name = json['name'];
    url = json['url'];
  }

  String? name;
  String? url;
}
