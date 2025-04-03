import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../media_picker_widget.dart';
import 'media_manager.dart';

/// A widget representing a selectable media tile in a grid.
///
/// This widget displays a thumbnail of the media file and supports selection.
/// If the media is a video, it also displays its duration.
///
/// - [media] represents the media item being displayed.
/// - [onSelected] is a callback triggered when the media is selected.
/// - [onThumbnailLoad] is an optional callback for when the thumbnail loads.
/// - [isSelected] determines if the tile is selected.
/// - [selectionIndex] shows the selection order when multiple files are selected.
class MediaTile extends StatelessWidget {
  /// Creates a [MediaTile] widget.
  const MediaTile({
    super.key,
    required this.media,
    required this.onSelected,
    this.onThumbnailLoad,
    this.isSelected = false,
    this.selectionIndex,
  });

  /// The media object associated with this tile.
  final MediaViewModel media;

  /// Callback triggered when the tile is selected.
  final Function(MediaViewModel media) onSelected;

  /// Whether the tile is currently selected.
  final bool isSelected;

  /// Callback triggered when the thumbnail loads.
  final ValueChanged<Uint8List?>? onThumbnailLoad;

  /// The selection index when multiple media files are selected.
  final int? selectionIndex;

  /// Duration for selection animation.
  final Duration _duration = const Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    // Load the media thumbnail asynchronously.
    var loadThumb = Future<Uint8List?>(() async {
      var thumb = await media.thumbnailAsync;
      onThumbnailLoad?.call(thumb);
      return thumb;
    });

    return FutureBuilder<Uint8List?>(
      future: loadThumb,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox();
        if (!snapshot.hasData) {
          return const Skeleton.replace(
            child: Bone(
              height: 100,
              width: 100,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(0.5),
          child: Stack(
            children: [
              Positioned.fill(
                child: media.thumbnail != null
                    ? GestureDetector(
                  onTap: () => onSelected(media),
                  child: Stack(
                    children: [
                      // Display the media thumbnail with an optional blur effect when selected.
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ClipRect(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: isSelected ? 5 : 0,
                                sigmaY: isSelected ? 5 : 0,
                              ),
                              child: Image.memory(
                                media.thumbnail!,
                                cacheWidth: 250, // Adjust as needed
                                cacheHeight: 250,
                                filterQuality: FilterQuality.low,
                                key: ValueKey<String>(media.id),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Overlay when the tile is selected.
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1 : 0,
                          curve: Curves.easeOut,
                          duration: _duration,
                          child: ClipRect(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black26,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Video duration label (if media is a video).
                      if (media.type == MediaType.video)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              _formatDuration(media.videoDuration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.grey.shade400,
                    size: 40,
                  ),
                ),
              ),

              // Selection indicator (checkmark or selection index).
              if (isSelected)
                Transform.translate(
                  offset: Offset.fromDirection(1, -4),
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: selectionIndex == null
                          ? const Icon(
                        Icons.done,
                        size: 16,
                        color: Colors.white,
                      )
                          : Text(
                        selectionIndex.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Formats a [Duration] into a human-readable string.
  ///
  /// - If the duration is less than an hour, it returns `mm:ss`.
  /// - If the duration is an hour or more, it returns `hh:mm:ss`.
  String _formatDuration(Duration? duration) {
    if (duration == null) return "";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours == 0) return "$minutes:$seconds";
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }
}
