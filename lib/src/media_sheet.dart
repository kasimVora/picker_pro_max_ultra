import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';
import 'custom_loading.dart';
import 'loading_status.dart';
import 'media_manager.dart';
import 'media_tile.dart';

/// Displays a bottom sheet with a grid of media (images or videos) for the user to select from.
///
/// The user can select up to [maxLimit] media files. The selected files will be returned
/// as a list of [MediaViewModel] objects when the bottom sheet is dismissed by tapping "Done".
/// Returns `null` if the bottom sheet is dismissed or "Cancel" is pressed.
///
/// [context] - The [BuildContext] to show the bottom sheet in.
/// [maxLimit] - The maximum number of media items the user can select.
Future<List<String>> showGridBottomSheet(
    BuildContext context,
    int maxLimit,
    MediaType type,
    String cancelText,
    String doneText,
    ) async {
  final result = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 5,
              )
            ],
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.70,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _MediaPickerBottomSheet(
                  maxLimit: maxLimit,
                  mediaType: type,
                  cancelText: cancelText,
                  doneText: doneText,
                ),
              );
            },
          ),
        ),
      );
    },
  );

  return result ?? [];
}


/// A widget that displays a media picker inside a bottom sheet with folder tabs,
/// a scrollable grid of media assets, and a selectable UI.
///
/// This widget supports pagination, lazy loading, and selection limits.
class _MediaPickerBottomSheet extends StatefulWidget {
  /// The maximum number of media files the user can select.
  final int maxLimit;

  final String cancelText, doneText;

  final MediaType mediaType;

  const _MediaPickerBottomSheet(
      {required this.maxLimit,
      required this.mediaType,
      required this.cancelText,
      required this.doneText});

  @override
  State<_MediaPickerBottomSheet> createState() =>
      _MediaPickerBottomSheetState();
}

class _MediaPickerBottomSheetState extends State<_MediaPickerBottomSheet> {
  final ScrollController _scrollController = ScrollController();

  /// The list of media folders (albums).
  List<AssetPathEntity> mediaFolders = [];

  /// The list of media files (images/videos) currently displayed.
  List<MediaViewModel> mediaFiles = MediaViewModel.dummyList();

  /// The list of media files selected by the user.
  List<MediaViewModel> selectedFiles = [];

  /// The index of the currently selected media folder.
  int tabIndex = 0;

  /// The current page index for pagination.
  int currentPage = 0;

  /// The number of media items to load per page.
  final int pageLimit = 12;

  /// Whether the selection limit has been reached.
  bool isLimitFinished = false;

  /// The current loading status for the grid.
  LoadStatus loadStatus = LoadStatus.initial;

  @override
  void initState() {
    super.initState();
    init();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        fetchMediaOfAlbum(tabIndex);
      }
    });
  }

  /// Initializes the media folders and the first page of media.
  Future<void> init() async {
    await fetchAlbums(widget.mediaType == MediaType.video
        ? RequestType.video
        : widget.mediaType == MediaType.audio
            ? RequestType.audio
            : RequestType.image);
    if (mediaFolders.isNotEmpty) {
      await fetchMediaOfAlbum(0);
    }
  }

  /// Fetches the list of media albums containing at least one asset.
  ///
  /// [type] specifies whether to load images, videos, or both.
  Future<void> fetchAlbums(RequestType type) async {
    final temp = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: type,
    );

    List<AssetPathEntity> filtered = [];
    for (final album in temp) {
      final count = await album.assetCountAsync;
      if (count > 0) filtered.add(album);
    }

    setState(() {
      mediaFolders = filtered;
    });
  }

  /// Fetches a paginated list of media from the selected album by [index].
  ///
  /// Updates the [mediaFiles] list and appends the results.
  Future<void> fetchMediaOfAlbum(int index) async {
    if (loadStatus == LoadStatus.loadingMore) return;

    if (index != tabIndex) {
      currentPage = 0;
      tabIndex = index;
      mediaFiles = MediaViewModel.dummyList();
    }

    setState(() {
      loadStatus =
          currentPage == 0 ? LoadStatus.loading : LoadStatus.loadingMore;
    });

    final folder = mediaFolders[tabIndex];
    final start = currentPage * pageLimit;
    final end = start + pageLimit;

    final assets = await folder.getAssetListRange(start: start, end: end);
    final media = <MediaViewModel>[];

    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) {
        media.add(await MediaViewModel.toMediaViewModel(asset));
      }
    }

    setState(() {
      if (currentPage == 0) mediaFiles.clear();
      mediaFiles.addAll(media);
      currentPage++;
      loadStatus = LoadStatus.success;
    });
  }

  /// Handles selection and deselection of a media file.
  ///
  /// [media] is the file to be toggled.
  void onFileSelect(MediaViewModel media) {
    setState(() {
      if (selectedFiles.any((t) => t.id == media.id)) {
        selectedFiles.removeWhere((f) => f.id == media.id);
        isLimitFinished = false;
      } else {
        if (selectedFiles.length < widget.maxLimit) {
          selectedFiles.add(media);
          isLimitFinished = selectedFiles.length == widget.maxLimit;
        } else {
          isLimitFinished = true;
        }
      }
    });
  }

  /// Returns the selection index (1-based) of the given media, or null if not selected.
  int? getSelectionIndex(MediaViewModel media) {
    final index = selectedFiles.indexWhere((element) => element.id == media.id);
    return index == -1 ? null : index + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /// Folder Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: List.generate(mediaFolders.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      if (loadStatus != LoadStatus.loading) {
                        await fetchMediaOfAlbum(index);
                      }
                    },
                    child: Shimmer(
                      visible: false,
                      replacement: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: tabIndex == index
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.15)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: tabIndex == index
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          mediaFolders[index].name.isEmpty
                              ? "Unknown"
                              : mediaFolders[index].name,
                          style: TextStyle(
                            color: tabIndex == index
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      child: Container(
                        width: 100,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          /// Media Grid
          Visibility(
            visible: mediaFiles.isNotEmpty,
            replacement: Expanded(
              child: Center(
                child: Text("No ${widget.mediaType.name} file found on this device"),
              ),
            ),
            child: Expanded(
              child: GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: mediaFiles.length,
                itemBuilder: (context, index) {
                  final media = mediaFiles[index];
                  return Shimmer(
                    visible: loadStatus == LoadStatus.loading,
                    replacement: MediaTile(
                      media: media,
                      onThumbnailLoad: (thumb) {
                        media.thumbnail = thumb;
                        setState(() {});
                      },
                      onSelected: (_) {
                        onFileSelect(media);
                        if (widget.maxLimit == 1) {
                          Navigator.pop(context, [media.mediaFile?.path ?? ""]);
                        }
                        setState(() {});
                      },
                      isSelected: selectedFiles.any((t) => t.id == media.id),
                      selectionIndex: getSelectionIndex(media),
                    ),
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// Action Buttons
          Visibility(
            visible: mediaFolders.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 10, right: 10),
              child: Row(
                spacing: 12,
                children: [

                  Expanded(
                    child: InkWell(
                    onTap: () => Navigator.pop(context, <String>[]),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          border: Border.all(
                            color:  Theme.of(context).primaryColor
                          )
                        ),
                        child: Center(child: Text(widget.cancelText,)),
                      ),
                    ),
                  ),


                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(
                            context,
                            selectedFiles.isNotEmpty
                                ? selectedFiles
                                .map((f) => f.mediaFile?.path ?? "")
                                .toList()
                                :  <String>[]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color:  Theme.of(context).primaryColor
                        ),
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                        child: Center(child: Text(widget.doneText,)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
