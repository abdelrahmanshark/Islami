import 'package:flutter/material.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/ui/home/widgets/no_internet_snackbar.dart';
import 'package:islami/utils/network_utils.dart';

/// Shows the right snackbar after a failed play attempt.
///
/// Call-blocked attempts already show via [AppMessenger]; offline shows the
/// internet message; any other player error shows a generic message.
void showPlaybackFailureSnackBar(BuildContext context) {
  final PlaybackBlockReason? reason =
      AudioPlayerService.instance.consumeBlockReason();
  if (reason == PlaybackBlockReason.call) {
    return;
  }
  if (reason == PlaybackBlockReason.offline) {
    showNoInternetSnackBar(context);
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(NetworkUtils.genericFailureMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
