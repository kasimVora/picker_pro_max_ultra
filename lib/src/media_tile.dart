import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../media_picker_widget.dart';
import 'media_manager.dart';



class MediaTile extends StatelessWidget {
  MediaTile({
    Key? key,
    required this.media,
    required this.onSelected,
    this.onThumbnailLoad,
    this.isSelected = false,
    this.selectionIndex,
  }) : super(key: key);

  final MediaViewModel media;
  final Function(MediaViewModel media) onSelected;
  final bool isSelected;
  final ValueChanged<Uint8List?>? onThumbnailLoad;
  final int? selectionIndex;

  final Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
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
                )
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
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ClipRect(
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: isSelected
                                            ? 5
                                            : 0,
                                        sigmaY: isSelected
                                            ? 5
                                            : 0,
                                      ),
                                      child: Image.memory(
                                        media.thumbnail!,
                                        cacheWidth: 250, // Adjust based on your needs
                                        cacheHeight: 250,
                                        filterQuality: FilterQuality.low,
                                        key: ValueKey<String>(media.id),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                              if (media.type == MediaType.video)
                                Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                        _printDuration(media.videoDuration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )),
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
                if (isSelected)
                      Transform.translate(
                        offset: Offset.fromDirection(1,-4),
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
                                    )),
                        ),
                      ),
              ],
            ),
          );
        });
  }

  String _printDuration(Duration? duration) {
    if (duration == null) return "";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours == 0) return "$twoDigitMinutes:$twoDigitSeconds";
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
