import 'package:flutter/material.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/ui/home/widgets/no_internet_snackbar.dart';

/// Shows the right snackbar after a failed play attempt.
///
/// Call-blocked attempts already show via [AppMessenger]; offline shows here.
void showPlaybackFailureSnackBar(BuildContext context) {
  final PlaybackBlockReason? reason =
      AudioPlayerService.instance.consumeBlockReason();
  if (reason == PlaybackBlockReason.call) {
    return;
  }
  showNoInternetSnackBar(context);
}
