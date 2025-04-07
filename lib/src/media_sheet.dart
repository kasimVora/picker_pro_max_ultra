import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
Future<List<MediaViewModel>?> showGridBottomSheet(
    BuildContext context, int maxLimit) {
  return showModalBottomSheet<List<MediaViewModel>?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _MediaPickerBottomSheet(maxLimit: maxLimit);
        },
      );
    },
  );
}

/// A widget that displays a media picker inside a bottom sheet with folder tabs,
/// a scrollable grid of media assets, and a selectable UI.
///
/// This widget supports pagination, lazy loading, and selection limits.
class _MediaPickerBottomSheet extends StatefulWidget {
  /// The maximum number of media files the user can select.
  final int maxLimit;

  const _MediaPickerBottomSheet({required this.maxLimit});

  @override
  State<_MediaPickerBottomSheet> createState() =>
      _MediaPickerBottomSheetState();
}

class _MediaPickerBottomSheetState extends State<_MediaPickerBottomSheet> {
  final ScrollController _scrollController = ScrollController();

  /// The list of media folders (albums).
  List<AssetPathEntity> mediaFolders = [];

  /// The list of media files (images/videos) currently displayed.
  List<MediaViewModel> mediaFiles = [];

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
    await fetchAlbums(RequestType.image);
    await fetchMediaOfAlbum(0);
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Media Folder Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(mediaFolders.length, (index) {
                return InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () async {
                    if (loadStatus != LoadStatus.loading) {
                      await fetchMediaOfAlbum(index);
                    }
                  },
                  child: Skeletonizer(
                    enabled: loadStatus == LoadStatus.loading &&
                        mediaFolders.isEmpty,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: tabIndex == index
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(mediaFolders[index].name),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          /// Media Grid
          Expanded(
            child: Skeletonizer(
              enabled: loadStatus == LoadStatus.loading,
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: mediaFiles.length,
                itemBuilder: (context, index) {
                  final media = mediaFiles[index];
                  return MediaTile(
                    media: media,
                    onThumbnailLoad: (thumb) {
                      media.thumbnail = thumb;
                      setState(() {});
                    },
                    onSelected: (_) {
                      onFileSelect(media);
                      if (widget.maxLimit == 1) {
                        Navigator.pop(context, [media]);
                      }
                    },
                    isSelected: selectedFiles.any((t) => t.id == media.id),
                    selectionIndex: getSelectionIndex(media),
                  );
                },
              ),
            ),
          ),

          /// Bottom Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context, null),
                child:  Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Cancel",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(
                      context, selectedFiles.isNotEmpty ? selectedFiles : null);
                },
                child:  Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Done",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
