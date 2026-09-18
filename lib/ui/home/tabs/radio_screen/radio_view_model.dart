import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/radio/radio_repository.dart';
import 'package:islami/domain/repositories/radio_repository.dart';
import 'package:islami/models/radio_response.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../../services/audio_player_service.dart';
import '../quran_screen/quran_resources.dart';

class RadioViewModel extends ChangeNotifier {
  RadioViewModel({RadioRepository? radioRepository})
    : _radioRepository = radioRepository ?? RadioRepositoryImpl() {
    _restorePlaybackState();
    getRadios();
    getReciters();
    _listenForReciterCompletion();
  }

  final RadioRepository _radioRepository;
  final AudioPlayerService _audioService = AudioPlayerService.instance;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  List<int> filterSearch = List.generate(114, (index) => index);
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
  int? selectedRadioId; // source of truth for playing radio
  int? selectedRadioForSoundId; // source of truth for muted radio
  int? selectedReciterId; // source of truth for playing reciter
  int currentSura = 1;
  late final player = _audioService.player;
  int toggleSwitchIndex = 0;
  bool isRepeatEnabled = false;
  bool isAutoNextEnabled = false;

  // Restore ids from the singleton so UI survives leaving the Radio tab.
  void _restorePlaybackState() {
    selectedRadioId = _audioService.selectedRadioId;
    selectedRadioForSoundId = _audioService.selectedRadioForSoundId;
    selectedReciterId = _audioService.selectedReciterId;
    currentSura = _audioService.currentSura;
    isRepeatEnabled = _audioService.isRepeatEnabled;
    isAutoNextEnabled = _audioService.isAutoNextEnabled;
  }

  // Persist radio play selection on the singleton.
  void _setSelectedRadio(Radios? radio) {
    selectedRadio = radio;
    selectedRadioId = radio?.id;
    _audioService.selectedRadioId = radio?.id;
  }

  // Persist mute selection on the singleton.
  void _setSelectedRadioForSound(Radios? radio) {
    selectedRadioForSound = radio;
    selectedRadioForSoundId = radio?.id;
    _audioService.selectedRadioForSoundId = radio?.id;
  }

  // Persist reciter play selection on the singleton.
  void _setSelectedReciter(Reciters? reciter) {
    selectedReciter = reciter;
    selectedReciterId = reciter?.id;
    _audioService.selectedReciterId = reciter?.id;
  }

  // Persist current sura on the singleton.
  void _setCurrentSura(int sura) {
    currentSura = sura;
    _audioService.currentSura = sura;
  }

  // Called when user picks a sura before opening RecitersScreen.
  void updateCurrentSura(int sura) {
    _setCurrentSura(sura);
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

  // Re-bind selected radio objects to the new API list by id.
  void _syncSelectedRadiosFromList() {
    if (selectedRadioId != null) {
      for (final radio in radios) {
        if (radio.id == selectedRadioId) {
          selectedRadio = radio;
          break;
        }
      }
    }
    if (selectedRadioForSoundId != null) {
      for (final radio in radios) {
        if (radio.id == selectedRadioForSoundId) {
          selectedRadioForSound = radio;
          break;
        }
      }
    }
  }

  // Re-bind selected reciter to the new API list by id.
  void _syncSelectedReciterFromList() {
    if (selectedReciterId == null) return;
    for (final reciter in reciters) {
      if (reciter.id == selectedReciterId) {
        selectedReciter = reciter;
        break;
      }
    }
  }

  Future<void> getRadios() async {
    radioIsLoading = true;
    notifyListeners();
    try {
      radios = await _radioRepository.getRadios();
      filteredRadios = radios;
      _syncSelectedRadiosFromList();
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
      reciters = await _radioRepository.getReciters();
      filteredReciters = reciters;
      _syncSelectedReciterFromList();
      reciterIsLoading = false;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      reciterIsLoading = false;
      reciterFailureMsg = 'something went wrong';
      notifyListeners();
    }
  }

  Future<void> playRadio(Radios radio) async {
    if (selectedRadioId != null && selectedRadioId == radio.id) {
      await player.pause();
      _setSelectedRadio(null);
    } else {
      try {
        // Radio should not inherit reciter loop mode.
        await player.setLoopMode(LoopMode.off);
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(radio.url ?? ''),
            tag: MediaItem(
              id: 'radio_${radio.id}',
              title: radio.name ?? 'Radio',
              artist: 'Islami',
            ),
          ),
        );
        player.play();
        _setSelectedReciter(null);
        _setSelectedRadio(radio);
      } catch (e) {
        log(e.toString());
        rethrow;
      }
    }
    notifyListeners();
  }

  // Listens for track end so auto-next can play the next surah.
  void _listenForReciterCompletion() {
    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          isAutoNextEnabled &&
          selectedReciter != null) {
        recitersNext(selectedReciter!);
      }
    });
  }

  // Turns repeat on/off; enabling it disables auto-next.
  Future<void> toggleRepeat() async {
    if (isRepeatEnabled) {
      isRepeatEnabled = false;
      await player.setLoopMode(LoopMode.off);
    } else {
      isRepeatEnabled = true;
      isAutoNextEnabled = false;
      await player.setLoopMode(LoopMode.one);
    }
    _audioService.isRepeatEnabled = isRepeatEnabled;
    _audioService.isAutoNextEnabled = isAutoNextEnabled;
    notifyListeners();
  }

  // Turns auto-next on/off; enabling it disables repeat.
  Future<void> toggleAutoNext() async {
    if (isAutoNextEnabled) {
      isAutoNextEnabled = false;
      await player.setLoopMode(LoopMode.off);
    } else {
      isAutoNextEnabled = true;
      isRepeatEnabled = false;
      await player.setLoopMode(LoopMode.off);
    }
    _audioService.isRepeatEnabled = isRepeatEnabled;
    _audioService.isAutoNextEnabled = isAutoNextEnabled;
    notifyListeners();
  }

  Future<void> muteSound(Radios radio) async {
    if (selectedRadioForSoundId != null &&
        selectedRadioForSoundId == radio.id) {
      await player.setVolume(1);
      _setSelectedRadioForSound(null);
    } else {
      await player.setVolume(0);
      _setSelectedRadioForSound(radio);
    }
    notifyListeners();
  }

  String get formatSura => currentSura.toString().padLeft(3, '0');

  Future<void> playReciter(Reciters reciter) async {
    if (selectedReciterId != null && selectedReciterId == reciter.id) {
      await player.pause();
      _setSelectedReciter(null);
    } else {
      try {
        String url = '${reciter.server}$formatSura.mp3';
        await player.setLoopMode(
          isRepeatEnabled ? LoopMode.one : LoopMode.off,
        );
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            tag: MediaItem(
              id: 'sura_$currentSura',
              title: 'سورة $currentSura',
              artist: reciter.name ?? 'قارئ',
            ),
          ),
        );
        player.play();
        _setSelectedRadio(null);
        _setSelectedReciter(reciter);
        _audioService.currentSura = currentSura;
      } catch (e) {
        log(e.toString());
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> recitersNext(Reciters reciter) async {
    if (currentSura < 114) {
      _setCurrentSura(currentSura + 1);
      String url = '${reciter.server}$formatSura.mp3';
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: 'sura_$currentSura',
            title: 'سورة $currentSura',
            artist: reciter.name ?? 'قارئ',
          ),
        ),
      );
      player.play();
      _setSelectedRadio(null);
      _setSelectedReciter(reciter);
      notifyListeners();
    }
  }

  Future<void> recitersBack(Reciters reciter) async {
    if (currentSura > 1) {
      _setCurrentSura(currentSura - 1);
      String url = '${reciter.server}$formatSura.mp3';
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: 'sura_$currentSura',
            title: 'سورة $currentSura',
            artist: reciter.name ?? 'قارئ',
          ),
        ),
      );
      player.play();
      _setSelectedRadio(null);
      _setSelectedReciter(reciter);
      notifyListeners();
    }
  }

  Future<void> seekReciter(Duration position) async {
    await player.seek(position);
  }

  String formatAudioTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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

  void onSearch(String newText) {
    List<int> suraResultSearch = [];

    for (int i = 0; i < QuranResources.englishQuranSuras.length; i++) {
      if (QuranResources.englishQuranSuras[i].toUpperCase().contains(
            newText.toUpperCase(),
          ) ||
          QuranResources.arabicQuranSuras[i].contains(newText)) {
        suraResultSearch.add(i);
      }
    }

    filterSearch = suraResultSearch;
    notifyListeners();
  }

  void onSuraTap(int index, BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.recitersRouteName, arguments: index);
  }

  void resetReciterSearch() {
    filteredReciters = reciters;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }
}
