import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';

/// Represents a media file (image or video) with metadata for display in a media picker.
class MediaViewModel {
  /// Unique identifier for the media file.
  final String id;

  /// A low-resolution image used as a preview thumbnail.
  Uint8List? thumbnail;

  /// Asynchronously fetches the thumbnail for the media file.
  final Future<Uint8List?>? thumbnailAsync;

  /// Type of the media (image, video, or unknown).
  final MediaType? type;

  /// The actual media file stored on the device.
  final File? mediaFile;

  /// Duration of the video file (if applicable).
  final Duration? videoDuration;

  /// Creates a new [MediaViewModel] instance.
  ///
  /// - [id] is required to uniquely identify the media.
  /// - [thumbnail] is an optional low-resolution image for quick preview.
  /// - [thumbnailAsync] allows asynchronous fetching of the thumbnail.
  /// - [type] specifies whether the media is an image or video.
  /// - [mediaFile] is the actual file object.
  /// - [videoDuration] is applicable only if the media is a video.
  MediaViewModel({
    required this.id,
    this.thumbnail,
    this.thumbnailAsync,
    this.type,
    this.videoDuration,
    this.mediaFile,
  });

  /// Generates a dummy list of media items for placeholder purposes.
  ///
  /// This is used to pre-populate lists with empty media items before real data is fetched.
  static List<MediaViewModel> dummyList() =>
      List.generate(20, (_) => MediaViewModel(id: "-1", mediaFile: File("")));

  /// Converts an [AssetEntity] (from the `photo_manager` package) into a [MediaViewModel].
  ///
  /// - [entity] is the media asset retrieved from the device gallery.
  /// - Determines the media type (image/video) based on the asset type.
  /// - Retrieves the media file and its thumbnail asynchronously.
  ///
  /// Returns a [Future] containing the converted [MediaViewModel].
  static Future<MediaViewModel> toMediaViewModel(AssetEntity entity) async {
    var mediaType = MediaType.unknown;
    if (entity.type == AssetType.video) mediaType = MediaType.video;
    if (entity.type == AssetType.image) mediaType = MediaType.image;
    if (entity.type == AssetType.audio) mediaType = MediaType.audio;

    return MediaViewModel(
      id: entity.id,
      thumbnailAsync: mediaType != MediaType.audio
          ? entity.thumbnailDataWithSize(const ThumbnailSize(200, 200))
          : null,
      type: mediaType,
      thumbnail: null,
      // Thumbnail is set asynchronously.
      mediaFile: await entity.file,
      videoDuration: entity.type == AssetType.video
          ? entity.videoDuration
          : entity.type == AssetType.audio
              ? Duration(seconds: entity.duration)
              : null,
    );
  }
}
