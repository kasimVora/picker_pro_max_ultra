import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';
import 'loading_status.dart';
import 'media_manager.dart';

/// Controller for managing media selection and album browsing.
class MediaPickerController extends GetxController {
  /// Maximum number of media items that can be selected.
  int maxLimit = 0;

  /// Type of media being selected (image, video, document, or unknown).
  MediaType mediaType = MediaType.image;

  /// Controller for handling scrolling behavior.
  final ScrollController scrollController = ScrollController();

  /// Current page index for pagination.
  RxInt currentPage = 0.obs;

  /// Number of media items loaded per page.
  int pageLimit = 12;

  /// Indicator for the last page index loaded.
  RxInt end = 0.obs;

  /// Stream of available media folders (albums).
  RxList<AssetPathEntity> mediaFoldersStream = <AssetPathEntity>[].obs;

  /// List of selected media files.
  RxList<MediaViewModel> selectedFile = <MediaViewModel>[].obs;

  /// Stream of media files available in the current album.
  RxList<MediaViewModel> mediaFilesStream = MediaViewModel.dummyList().obs;

  /// Current selected tab index.
  RxInt tabIndexStream = 0.obs;

  /// Flag indicating whether the selection limit has been reached.
  RxBool isLimitFinished = false.obs;

  /// Loading status of media fetching.
  Rx<LoadStatus> loadStatus = LoadStatus.initial.obs;

  /// Initializes the media picker by requesting permissions and loading albums.
  Future<void> init() async {
    await fetchAlbums(
        mediaType == MediaType.video ? RequestType.video : RequestType.image);
    await fetchMediaOfAlbum(0); // Load media from the first album by default.

    scrollController.addListener(() async {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        fetchMediaOfAlbum(tabIndexStream.value);
      }
    });
  }

  /// Fetches albums (folders) based on the requested media type.
  ///
  /// - [type]: The type of media to fetch (image, video, etc.).
  Future<void> fetchAlbums(RequestType type) async {
    var temp = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: type,
    );

    mediaFoldersStream.value = [];

    for (int i = 0; i < temp.length; i++) {
      var count = await temp[i].assetCountAsync;
      if (kDebugMode) {
        print("--- count $count -- name ${temp[i].type.toString()} ${temp[i].name.toString()}");
      }
      if (count != 0) {
        mediaFoldersStream.add(temp[i]);
      }
    }

    mediaFoldersStream.refresh();
  }

  /// Fetches media files from a selected album.
  ///
  /// - [index]: The index of the album to fetch media from.
  Future<void> fetchMediaOfAlbum(int index) async {
    if (loadStatus.value == LoadStatus.loadingMore) {
      return; // Prevent duplicate loads.
    }

    if (index != tabIndexStream.value) {
      currentPage.value = 0;
    }

    tabIndexStream.value = index; // Update tab index for view refresh.

    if (index < mediaFoldersStream.length) {
      loadStatus.value = currentPage.value == 0
          ? LoadStatus.loading
          : LoadStatus.loadingMore;

      final fetchedMedia = await _mediaFromFolder(
        mediaFoldersStream[index],
        index,
        page: currentPage.value,
        limit: pageLimit,
      );

      if (currentPage.value == 0) {
        mediaFilesStream.clear();
      }

      mediaFilesStream.addAll(fetchedMedia);
      mediaFilesStream.refresh();
      currentPage.value++;
      loadStatus.value = LoadStatus.success;
    }
  }

  /// Handles media selection and enforces the selection limit.
  ///
  /// - [media]: The media item being selected or deselected.
  void onFileSelect(MediaViewModel media) {
    if (selectedFile.any((t) => t.id == media.id)) {
      selectedFile.removeWhere((f) => f.id == media.id);
    } else {
      if (selectedFile.length < maxLimit) {
        selectedFile.add(media);
        if (selectedFile.length == maxLimit) {
          isLimitFinished.value = true;
        }
      } else {
        isLimitFinished.value = true;
      }
    }
    selectedFile.refresh();
  }

  /// Retrieves media files from a specific folder with pagination.
  ///
  /// - [assetPathEntity]: The album/folder containing media.
  /// - [index]: The index of the album in the folder list.
  /// - [page]: The current page being loaded.
  /// - [limit]: The number of items per page.
  ///
  /// Returns a list of fetched [MediaViewModel] objects.
  Future<List<MediaViewModel>> _mediaFromFolder(
      AssetPathEntity assetPathEntity,
      int index, {
        required int page,
        required int limit,
      }) async {
    List<MediaViewModel> fetchedFiles = [];
    final start = page * limit;
    final end = start + limit;

    List<AssetEntity> assets = await assetPathEntity.getAssetListRange(
      start: start,
      end: end,
    );

    for (var asset in assets) {
      final file = await asset.file;
      if (file != null) {
        fetchedFiles.add(await MediaViewModel.toMediaViewModel(asset));
      }
    }

    return fetchedFiles;
  }

  /// Retrieves the selection index of a media file.
  ///
  /// - [media]: The media file to check.
  ///
  /// Returns the 1-based index if selected, otherwise `null`.
  int? getSelectionIndex(MediaViewModel media) {
    var index = selectedFile.indexWhere((element) => element.id == media.id);
    if (index == -1) return null;
    return index + 1;
  }
}
