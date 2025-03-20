import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';
import 'loading_status.dart';
import 'media_manager.dart';

class MediaPickerController extends GetxController {
  int maxLimit = 0;
  MediaType mediaType = MediaType.image;
  final ScrollController scrollController = ScrollController();

  RxInt currentPage = 0.obs;
  int pageLimit = 12;
  RxInt end = 0.obs;

  RxList<AssetPathEntity> mediaFoldersStream = <AssetPathEntity>[].obs;
  RxList<MediaViewModel> selectedFile = <MediaViewModel>[].obs;
  RxList<MediaViewModel> mediaFilesStream = MediaViewModel.dummyList().obs;
  RxInt tabIndexStream = 0.obs;
  RxBool isLimitFinished = false.obs;

  Rx<LoadStatus> loadStatus = LoadStatus.initial.obs;

  // Initialize MediaPickerBloc and ask for permissions
  Future<void> init() async {
    await fetchAlbums(mediaType == MediaType.video ? RequestType.video : RequestType.image);
    await fetchMediaOfAlbum(0); // load media from the first album by default

    scrollController.addListener(() async {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        fetchMediaOfAlbum(tabIndexStream.value);
      }
    });
  }

  Future<void> fetchAlbums(RequestType type) async {

    var temp = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: type,
    );

    mediaFoldersStream.value = [];

    for (int i = 0; i < temp.length; i++) {
      var d = await temp[i].assetCountAsync;
      if (kDebugMode) {
        print(
            "--- count $d -- name ${temp[i].type.toString()} ${temp[i].name.toString()}");
      }
      if (d != 0) {
        mediaFoldersStream.add(temp[i]);
      }
    }

    mediaFoldersStream.refresh();
  }

  Future<void> fetchMediaOfAlbum(int index) async {
    if (loadStatus.value == LoadStatus.loadingMore) {
      return; // Prevent duplicate loads
    }

    if (index != tabIndexStream.value) {
      currentPage.value = 0;
    }

    tabIndexStream.value = index; // added here to update view first

    if (index < mediaFoldersStream.length) {
      if (currentPage.value == 0) {
        loadStatus.value = LoadStatus.loading;
      } else {
        loadStatus.value = LoadStatus.loadingMore;
      }

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

  void onFileSelect(MediaViewModel media) {
    if (selectedFile.any((t) => t.id == media.id)) {
      selectedFile.removeWhere((f) => f.id == media.id);
    } else {
      if (selectedFile.length != maxLimit) {
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
        fetchedFiles.add( await MediaViewModel.toMediaViewModel(asset));
      }
    }

    // tabIndexStream.value = index ;
    return fetchedFiles;
  }

  int? getSelectionIndex(MediaViewModel media) {
    var index = selectedFile.indexWhere((element) => element.id == media.id);
    if (index == -1) return null;
    return index + 1;
  }
}
