import 'package:flutter/material.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/models/radio_response.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/models/sermon.dart';
import 'package:islami/ui/home/home_screen_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/widgets/mini_audio_player_frame.dart';
import 'package:islami/ui/home/widgets/mini_lecture_controls.dart';
import 'package:islami/ui/home/widgets/mini_player_animated_switcher.dart';
import 'package:islami/ui/home/widgets/mini_quran_controls.dart';
import 'package:islami/ui/home/widgets/mini_radio_controls.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:provider/provider.dart';

/// Mini player for audio started from the Radio tab
/// (radio station, reciter, sermon, or Sha'rawy lecture).
class MiniRadioTabPlayer extends StatelessWidget {
  const MiniRadioTabPlayer({super.key});

  /// Opens the Radio tab → segment → list of the playing item and scrolls
  /// to its card; reciters open their own screen on the playing sura.
  Future<void> _openActiveAudio(
    BuildContext context,
    RadioViewModel viewModel,
  ) async {
    final HomeScreenViewModel homeViewModel = context
        .read<HomeScreenViewModel>();
    await homeViewModel.openTab(HomeScreenViewModel.radioTabIndex);
    await viewModel.showActiveAudio();

    final Reciters? reciter = viewModel.selectedReciter;
    if (reciter != null && context.mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.recitersRouteName,
        arguments: reciter,
      );
    }
  }

  /// Runs a play action and shows the same failure snackbar as the cards.
  /// [playAction] is a function that returns true when playback worked.
  Future<void> _play(
    BuildContext context,
    Future<bool> Function() playAction,
  ) async {
    final bool played = await playAction();
    if (!played && context.mounted) {
      showPlaybackFailureSnackBar(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, viewModel, child) {
        final Radios? radio = viewModel.selectedRadio;
        final Reciters? reciter = viewModel.selectedReciter;
        final Sermon? sermon = viewModel.selectedSermon;
        final QuranStoryLecture? lecture = viewModel.selectedSharawyLecture;

        Widget? controls;
        if (radio != null) {
          controls = MiniRadioControls(
            isSoundOn: viewModel.selectedRadioForSoundId != radio.id,
            onPause: () => _play(context, () => viewModel.playRadio(radio)),
            onToggleSound: () => viewModel.muteSound(radio),
          );
        } else if (reciter != null) {
          controls = MiniQuranControls(
            isPlaying: viewModel.isReciterPlaying,
            isRepeatEnabled: viewModel.isRepeatEnabled,
            isAutoNextEnabled: viewModel.isAutoNextEnabled,
            speedLabel: viewModel.playbackSpeedLabel,
            onStop: viewModel.stopReciter,
            onToggleRepeat: viewModel.toggleRepeat,
            onPrevious: () =>
                _play(context, () => viewModel.recitersBack(reciter)),
            onPlayPause: () =>
                _play(context, () => viewModel.playReciter(reciter)),
            onNext: () => _play(context, () => viewModel.recitersNext(reciter)),
            onToggleAutoNext: viewModel.toggleAutoNext,
            onChangeSpeed: viewModel.cyclePlaybackSpeed,
          );
        } else if (sermon != null) {
          controls = MiniLectureControls(
            isPlaying: viewModel.player.playing,
            speedLabel: viewModel.playbackSpeedLabel,
            onStop: viewModel.stopSermon,
            onPlayPause: () =>
                _play(context, () => viewModel.playSermon(sermon)),
            onChangeSpeed: viewModel.cyclePlaybackSpeed,
          );
        } else if (lecture != null) {
          controls = MiniLectureControls(
            isPlaying: viewModel.player.playing,
            speedLabel: viewModel.playbackSpeedLabel,
            onStop: viewModel.stopSharawyLecture,
            onPlayPause: () =>
                _play(context, () => viewModel.playSharawyLecture(lecture)),
            onChangeSpeed: viewModel.cyclePlaybackSpeed,
          );
        }

        // The last frame is kept by the switcher, so it animates out
        // with its content even after the selection is cleared.
        Widget content;
        if (controls == null) {
          content = const SizedBox.shrink(key: ValueKey('mini_hidden'));
        } else {
          content = MiniAudioPlayerFrame(
            key: const ValueKey('mini_frame'),
            title: viewModel.activeAudioTitle,
            controls: controls,
            onTap: () => _openActiveAudio(context, viewModel),
          );
        }

        return MiniPlayerAnimatedSwitcher(child: content);
      },
    );
  }
}
