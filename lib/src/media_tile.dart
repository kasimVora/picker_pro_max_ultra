import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../media_picker_widget.dart';
import '../platform_config.dart';
import 'custom_loading.dart';
import 'media_manager.dart';

/// A widget that displays a media item (image, video, or audio) in a grid tile format.
///
/// This tile handles:
/// - Thumbnail loading and display
/// - Selection state visualization
/// - Media type indicators (duration for video/audio)
/// - Tap and long-press interactions
class MediaTile extends StatelessWidget {
  /// Creates a media tile widget.
  ///
  /// [media]: The media view model containing information about the media file.
  /// [onSelected]: Callback when the tile is tapped.
  /// [isSelected]: Whether this media item is currently selected.
  /// [onThumbnailLoad]: Optional callback when the thumbnail is loaded.
  /// [selectionIndex]: Optional index to display when selected (for multi-select).
  const MediaTile({
    super.key,
    required this.media,
    required this.onSelected,
    this.onThumbnailLoad,
    this.isSelected = false,
    this.selectionIndex,
  });

  /// The media view model containing information about the media file.
  final MediaViewModel media;

  /// Callback function invoked when the tile is tapped.
  final Function(MediaViewModel media) onSelected;

  /// Whether this media item is currently selected.
  final bool isSelected;

  /// Optional callback that provides the loaded thumbnail data.
  final ValueChanged<Uint8List?>? onThumbnailLoad;

  /// Optional index to display when selected (for multi-select scenarios).
  final int? selectionIndex;

  @override
  Widget build(BuildContext context) {
    final customPickerTheme = Theme.of(context).extension<PickerThemeData>();

    // Load thumbnail asynchronously
    var loadThumb = Future<Uint8List?>(() async {
      Uint8List? thumb = await media.thumbnailAsync;
      onThumbnailLoad?.call(thumb);
      return thumb;
    });

    return FutureBuilder<Uint8List?>(
      future: loadThumb,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox();
        if (media.type != MediaType.audio && !snapshot.hasData) {
          return Shimmer(
            visible: !snapshot.hasData,
            replacement: const SizedBox(),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: customPickerTheme?.tabEnableColor ??
                        Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => onSelected(media),
                    onLongPress: () {
                      if (media.type == MediaType.image &&
                          media.mediaFile != null) {
                        showImageDialog(context, media.mediaFile!);
                      } else {
                        showCustomToast(
                          context,
                          "${media.mediaFile?.fileName ?? ""} - ${twoDigits(media.videoDuration!.inMinutes)}:${twoDigits(media.videoDuration!.inSeconds)}",
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: media.type == MediaType.audio
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      CupertinoIcons.music_note,
                                      size: 36,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                )
                              : Image.memory(
                                  media.thumbnail!,
                                  cacheWidth: 250,
                                  cacheHeight: 250,
                                  filterQuality: FilterQuality.low,
                                  key: ValueKey<String>(media.id),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (isSelected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        if (media.type != MediaType.image)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatDuration(media.videoDuration),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: customPickerTheme?.tabEnableColor ??
                            Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: selectionIndex == null
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : Text(
                                selectionIndex.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Formats a duration into HH:MM:SS or MM:SS format.
  ///
  /// [duration]: The duration to format.
  /// Returns a formatted duration string.
  String _formatDuration(Duration? duration) {
    if (duration == null) return "";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours == 0) return "$minutes:$seconds";
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }

  /// Shows a full-screen dialog with the image for better viewing.
  ///
  /// [context]: The build context.
  /// [file]: The image file to display.
  void showImageDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          insetPadding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 1,
                  maxScale: 4,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.6,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a custom toast message at the bottom of the screen.
  ///
  /// [context]: The build context.
  /// [message]: The message to display.
  void showCustomToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2))
        .then((_) => overlayEntry.remove());
  }

  /// Converts a number to two digits with leading zero if needed.
  ///
  /// [n]: The number to convert.
  /// Returns a two-digit string representation.
  String twoDigits(int n) => n.toString().padLeft(2, '0');
}
