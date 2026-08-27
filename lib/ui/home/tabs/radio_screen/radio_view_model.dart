import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/api_manger/api_manger.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/RecitersResponse.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:just_audio/just_audio.dart';

import 'models/RadioResponce.dart';

class RadioViewModel extends ChangeNotifier {
  bool radioIsLoading = false;
  bool reciterIsLoading = false;
  List<Radios> radios = [];
  List<Radios> filteredRadios = [];
  List<Reciters> reciters = [];
  List<Reciters> filteredReciters = [];
  String radioFailureMsg = '';
  String reciterFailureMsg = '';
  Radios? selectedRadio;
  Radios? selectedRadioForSound;
  Reciters? selectedReciter;
  int _currentSura = 1;
  final player = AudioPlayer();
  int toggleSwitchIndex = 0;

  RadioViewModel() {
    getRadios();
    getReciters();
  }

  void changeToggleIndex(int index) {
    toggleSwitchIndex = index;
    notifyListeners();
  }

  TextStyle switcherTextStyle(int index) {
    if (toggleSwitchIndex == index) {
      return AppStyles.blackBold18;
    } else {
      return AppStyles.whiteBold16;
    }
  }

  Future<void> getRadios() async {
    radioIsLoading = true;
    notifyListeners();
    try {
      RadioResponse radiosResponse = await ApiManger.getRadioResponse();
      radios = radiosResponse.radios ?? [];
      filteredRadios = radios;
      radioIsLoading = false;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      radioIsLoading = false;
      radioFailureMsg = 'some thing went Wrong';
      notifyListeners();
    }
  }

  Future<void> getReciters() async {
    reciterIsLoading = true;
    notifyListeners();
    try {
      var recitersResponse = await ApiManger.getRecitersResponse();
      reciters = recitersResponse.reciters ?? [];
      reciterIsLoading = false;
      filteredReciters = reciters;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      reciterIsLoading = false;
      reciterFailureMsg = 'something went wrong';
      notifyListeners();
    }
  }

  Future<void> playRadio(Radios radio) async {
    if (selectedRadio == radio) {
      await player.pause();
      selectedRadio = null;
    } else {
      try {
        await player.setUrl(radio.url ?? '');
        player.play();
        selectedRadio = radio;
      } catch (e) {
        log(e.toString());
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> muteSound(Radios radio) async {
    if (selectedRadioForSound == radio) {
      await player.setVolume(1);
      selectedRadioForSound = null;
    } else {
      await player.setVolume(0);
      selectedRadioForSound = radio;
    }
    notifyListeners();
  }

  String get formatSura => _currentSura.toString().padLeft(3, '0');

  Future<void> playReciter(Reciters reciter) async {
    if (selectedReciter == reciter) {
      await player.pause();
      selectedReciter = null;
    } else {
      try {
        String url = '${reciter.moshaf?.first.server}$formatSura.mp3';
        await player.setUrl(url);
        player.play();
        selectedReciter = reciter;
      } catch (e) {
        log(e.toString());
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> recitersNext(Reciters reciter) async {
    if (_currentSura < 114) {
      _currentSura++;
      String url = '${reciter.moshaf?.first.server}$formatSura.mp3';
      await player.setUrl(url);
      player.play();
      selectedReciter = reciter;
      notifyListeners();
    }
  }

  Future<void> recitersBack(Reciters reciter) async {
    if (_currentSura > 1) {
      _currentSura--;
      String url = '${reciter.moshaf?.first.server}$formatSura.mp3';
      await player.setUrl(url);
      player.play();
      selectedReciter = reciter;
      notifyListeners();
    }
  }

  void filterRadio(String newText) {
    if (newText.isEmpty) {
      filteredRadios = radios;
    } else {
      filteredRadios = radios.where((radio) {
        return radio.name?.contains(newText) ?? false;
      }).toList();
    }
    notifyListeners();
  }

  void filterReciter(String newText) {
    if (newText.isEmpty) {
      filteredReciters = reciters;
    } else {
      filteredReciters = reciters.where((reciters) {
        return reciters.name?.contains(newText) ?? false;
      }).toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    player.dispose();
    super.dispose();
  }
}
