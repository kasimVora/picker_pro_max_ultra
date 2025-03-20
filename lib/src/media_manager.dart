import 'dart:io';
import 'dart:typed_data';


import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';



///This class will contain the necessary data for viewing list of media
class MediaViewModel {
  ///Unique id to identify
  final String id;

  ///A low resolution image to show as preview
  Uint8List? thumbnail;

  ///Get Thumbnail of the media file
  final Future<Uint8List?>? thumbnailAsync;

  ///Type of the media, Image/Video
  final MediaType? type;

  final File? mediaFile;

  ///Duration of the video
  final Duration? videoDuration;

  MediaViewModel({
    required this.id,
    this.thumbnail,
    this.thumbnailAsync,
    this.type,
    this.videoDuration,
    this.mediaFile,
  });


  static List<MediaViewModel> dummyList ()=> List.generate(20, (_) =>
      MediaViewModel(
          id: "-1",
          mediaFile: File("")

      ));

  static Future<MediaViewModel> toMediaViewModel(AssetEntity entity) async{
    var mediaType = MediaType.unknown;
    if (entity.type == AssetType.video) mediaType = MediaType.video;
    if (entity.type == AssetType.image) mediaType = MediaType.image;
    return MediaViewModel(
      id: entity.id,
      thumbnailAsync: entity.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      type: mediaType,
      thumbnail: null,
      mediaFile: await entity.file,
      videoDuration: entity.type == AssetType.video ? entity.videoDuration : null,
    );
  }


 // static Future<List<File>> compressFiles(List<File> files) async {
 //    List<File> compressedFiles = [];
 //
 //    for (File file in files) {
 //      String extension = file.path.split('.').last.toLowerCase();
 //
 //      File? compressedFile;
 //
 //      if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
 //        compressedFile = await compressImage(file, extension);
 //      } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
 //        compressedFile = await compressVideo(file, extension);
 //      } else {
 //        compressedFile = file; // Keep other files unchanged
 //      }
 //
 //      if (compressedFile != null) {
 //        compressedFiles.add(compressedFile);
 //      }
 //    }
 //
 //    return compressedFiles;
 //  }
 //
 //  static Future<File> compressImage(File file, String extension) async {
 //    final dir = await getTemporaryDirectory();
 //    final outputPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$extension';
 //
 //    await FFmpegKit.execute(
 //      '-i ${file.path} -q:v 5 $outputPath', // Adjust `q:v` (1-31, lower is better quality)
 //    );
 //
 //    return File(outputPath).existsSync() ? File(outputPath) : file;
 //  }
 //
 //
 //
 //  static Future<File> compressVideo(File file, String extension) async {
 //    final dir = await getTemporaryDirectory();
 //    final outputPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$extension';
 //
 //    await FFmpegKit.execute(
 //      '-i ${file.path} -vcodec libx264 -crf 28 $outputPath', // Adjust `crf` (0-51, lower is better quality)
 //    );
 //
 //    return File(outputPath).existsSync() ? File(outputPath) : file;
 //  }



}
