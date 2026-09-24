import 'package:flutter/material.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/ui/home/home_screen_view_model.dart';
import 'package:islami/ui/home/widgets/mini_audio_player_frame.dart';
import 'package:islami/ui/home/widgets/mini_player_animated_switcher.dart';
import 'package:islami/ui/home/widgets/mini_quran_controls.dart';
import 'package:provider/provider.dart';

/// Mini player for a downloaded (offline) sura.
class MiniDownloadsPlayer extends StatelessWidget {
  const MiniDownloadsPlayer({super.key});

  /// Opens the Downloads tab (if needed), then the playing reciter,
  /// then scrolls to the playing sura.
  Future<void> _openPlayingDownload(
    BuildContext context,
    DownloadsViewModel viewModel,
  ) async {
    await context.read<HomeScreenViewModel>().openTab(
      HomeScreenViewModel.downloadsTabIndex,
    );
    viewModel.showPlayingReciter();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadsViewModel>(
      builder: (context, viewModel, child) {
        // The last frame is kept by the switcher, so it animates out
        // with its content even after the selection is cleared.
        Widget content;
        if (viewModel.playingSuraId == null) {
          content = const SizedBox.shrink(key: ValueKey('mini_hidden'));
        } else {
          content = MiniAudioPlayerFrame(
            key: const ValueKey('mini_frame'),
            title: viewModel.playingAudioTitle,
            controls: MiniQuranControls(
              isPlaying: viewModel.isPlaying,
              isRepeatEnabled: viewModel.isRepeatEnabled,
              isAutoNextEnabled: viewModel.isAutoNextEnabled,
              speedLabel: viewModel.playbackSpeedLabel,
              onStop: viewModel.stopPlayback,
              onToggleRepeat: viewModel.toggleRepeat,
              onPrevious: viewModel.playPreviousDownload,
              onPlayPause: viewModel.togglePlayback,
              onNext: viewModel.playNextDownload,
              onToggleAutoNext: viewModel.toggleAutoNext,
              onChangeSpeed: viewModel.cyclePlaybackSpeed,
            ),
            onTap: () => _openPlayingDownload(context, viewModel),
          );
        }

        return MiniPlayerAnimatedSwitcher(child: content);
      },
    );
  }
}
