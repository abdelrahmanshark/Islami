import 'package:flutter/material.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/ui/home/widgets/mini_downloads_player.dart';
import 'package:islami/ui/home/widgets/mini_player_animated_switcher.dart';
import 'package:islami/ui/home/widgets/mini_radio_tab_player.dart';
import 'package:provider/provider.dart';

/// Global mini player shown above the bottom bar while any audio is active.
///
/// Picks the player of the last audio source; each player animates itself
/// in/out based on its view model state.
class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        final ActiveAudioType? lastAudioType = audioService.lastActiveAudioType;

        Widget player;
        if (lastAudioType == null) {
          player = const SizedBox.shrink(key: ValueKey('mini_none'));
        } else if (lastAudioType == ActiveAudioType.download) {
          player = const MiniDownloadsPlayer(key: ValueKey('mini_downloads'));
        } else {
          player = const MiniRadioTabPlayer(key: ValueKey('mini_radio_tab'));
        }

        return MiniPlayerAnimatedSwitcher(child: player);
      },
    );
  }
}
