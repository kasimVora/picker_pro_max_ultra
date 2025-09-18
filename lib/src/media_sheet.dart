import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';
import '../platform_config.dart';
import 'custom_loading.dart';
import 'loading_status.dart';
import 'media_manager.dart';
import 'media_tile.dart';

/// Displays a bottom sheet for media selection with a grid view.
///
/// [context]: The build context to show the bottom sheet.
/// [maxLimit]: Maximum number of media items that can be selected.
/// [type]: The type of media to display (image, video, or audio).
/// [cancelText]: Text for the cancel button.
/// [doneText]: Text for the done button.
///
/// Returns a [Future<List<String>>] containing paths of selected media files.
Future<List<String>> showGridBottomSheet(
  BuildContext context,
  int maxLimit,
  MediaType type,
  String cancelText,
  String doneText,
  String moreText,
  String emptyText,
  String openSetting,
) async {
  final result = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final customPickerTheme = Theme.of(context).extension<PickerThemeData>();
      return ClipRRect(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(customPickerTheme?.borderRadius ?? 32)),
        child: Container(
          decoration: BoxDecoration(
            color: customPickerTheme?.bottomSheetBackgroundColor ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(customPickerTheme?.borderRadius ?? 32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    width: 60,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: customPickerTheme?.bottomSheetIndicatorColor ??
                          Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: _MediaPickerBottomSheet(
                      maxLimit: maxLimit,
                      mediaType: type,
                      cancelText: cancelText,
                      doneText: doneText,
                      moreText: moreText,
                      emptyText: emptyText,
                      openSetting: openSetting,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
  return result ?? [];
}

/// A private widget that displays the media picker content in a bottom sheet.
class _MediaPickerBottomSheet extends StatefulWidget {
  /// Maximum number of media items that can be selected.
  final int maxLimit;

  /// The type of media to display.
  final MediaType mediaType;

  /// Text for the cancel button.
  final String cancelText;

  /// Text for the done button.
  final String doneText;

  final String moreText;

  final String emptyText;

  final String openSetting;

  /// Creates a media picker bottom sheet.
  const _MediaPickerBottomSheet({
    required this.maxLimit,
    required this.mediaType,
    required this.cancelText,
    required this.doneText,
    required this.emptyText,
    required this.moreText,
    required this.openSetting,
  });

  @override
  State<_MediaPickerBottomSheet> createState() =>
      _MediaPickerBottomSheetState();
}

/// State class for [_MediaPickerBottomSheet].
class _MediaPickerBottomSheetState extends State<_MediaPickerBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  List<AssetPathEntity> mediaFolders = [];
  List<MediaViewModel> mediaFiles = MediaViewModel.dummyList();
  List<MediaViewModel> selectedFiles = [];
  int tabIndex = 0;
  int currentPage = 0;
  final int pageLimit = 12;
  bool isLimitFinished = false, isLimitedPermission = false;
  LoadStatus loadStatus = LoadStatus.initial;

  @override
  void initState() {
    super.initState();

    init();
    _scrollController.addListener(_scrollListener);
  }

  /// Listener for scroll events to implement infinite scrolling.
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      fetchMediaOfAlbum(tabIndex);
    }
  }

  /// Initializes the media picker by fetching albums and media.
  Future<void> init() async {
    if (widget.mediaType == MediaType.image ||
        widget.mediaType == MediaType.video) {
      final PermissionState ps = await PhotoManager.getPermissionState(
          requestOption: PermissionRequestOption(
              androidPermission: AndroidPermission(
                  type: widget.mediaType == MediaType.image
                      ? RequestType.image
                      : RequestType.video,
                  mediaLocation: false)));
      isLimitedPermission = ps == PermissionState.limited;
    }

    await fetchAlbums(widget.mediaType == MediaType.video
        ? RequestType.video
        : widget.mediaType == MediaType.audio
            ? RequestType.audio
            : RequestType.image);
    if (mediaFolders.isNotEmpty) await fetchMediaOfAlbum(0);
  }

  /// Fetches media albums from the device.
  ///
  /// [type]: The type of media to fetch (image, video, or audio).
  Future<void> fetchAlbums(RequestType type) async {
    final temp = await PhotoManager.getAssetPathList(hasAll: false, type: type);
    if (temp.isEmpty) {
      setState(() {
        loadStatus = LoadStatus.initial;
        mediaFiles = [];
        mediaFolders = [];
      });
      return;
    }
    List<AssetPathEntity> filtered = [];
    for (final album in temp) {
      final count = await album.assetCountAsync;
      if (count > 0) filtered.add(album);
    }

    setState(() {
      mediaFolders = filtered;
    });
  }

  /// Fetches media files from a specific album.
  ///
  /// [index]: The index of the album to fetch media from.
  Future<void> fetchMediaOfAlbum(int index) async {
    if (loadStatus == LoadStatus.loadingMore) return;
    if (index != tabIndex) {
      currentPage = 0;
      tabIndex = index;
      mediaFiles = MediaViewModel.dummyList();
    }

    setState(() => loadStatus =
        currentPage == 0 ? LoadStatus.loading : LoadStatus.loadingMore);

    final folder = mediaFolders[tabIndex];
    final start = currentPage * pageLimit;
    final end = start + pageLimit;
    final assets = await folder.getAssetListRange(start: start, end: end);
    final media = <MediaViewModel>[];

    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) media.add(await MediaViewModel.toMediaViewModel(asset));
    }

    setState(() {
      if (currentPage == 0) mediaFiles.clear();
      mediaFiles.addAll(media);
      currentPage++;
      loadStatus = LoadStatus.success;
    });
  }

  /// Handles selection/deselection of media files.
  ///
  /// [media]: The media file that was selected/deselected.
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

  /// Gets the selection index of a media file if it's selected.
  ///
  /// [media]: The media file to check.
  /// Returns the 1-based index if selected, or null if not selected.
  int? getSelectionIndex(MediaViewModel media) {
    final index = selectedFiles.indexWhere((element) => element.id == media.id);
    return index == -1 ? null : index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final customPickerTheme = Theme.of(context).extension<PickerThemeData>();
    return Container(
      decoration: BoxDecoration(
          color: customPickerTheme?.bottomSheetBackgroundColor ??
              Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: mediaFolders.isNotEmpty && isLimitedPermission,
            child: InkWell(
              onTap: () {
                PhotoManager.openSetting();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Text(
                      widget.moreText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(mediaFolders.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      mediaFolders[index].name.isEmpty
                          ? "Unknown"
                          : mediaFolders[index].name,
                      style: TextStyle(
                        fontSize: 14,
                        color: tabIndex == index
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: tabIndex == index,
                    onSelected: (_) async {
                      if (loadStatus != LoadStatus.loading) {
                        await fetchMediaOfAlbum(index);
                      }
                    },
                    selectedColor: customPickerTheme?.tabEnableColor ??
                        Theme.of(context).colorScheme.primary,
                    backgroundColor: customPickerTheme?.tabDisableColor ??
                        Theme.of(context).colorScheme.surface,
                    shape: StadiumBorder(
                      side: BorderSide(
                          color: tabIndex == index
                              ? Colors.transparent
                              : customPickerTheme?.tabBorderColor ??
                                  Colors.white),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: mediaFiles.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: widget.emptyText),
                            TextSpan(
                              text: " ${widget.openSetting}",
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  await PhotoManager.openSetting();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                },
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
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
                              Navigator.pop(
                                  context, [media.mediaFile?.path ?? ""]);
                            }
                          },
                          isSelected:
                              selectedFiles.any((t) => t.id == media.id),
                          selectionIndex: getSelectionIndex(media),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            minimum: EdgeInsets.symmetric(horizontal: 10),
            child: mediaFolders.isNotEmpty && widget.maxLimit > 1
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, <String>[]),
                          style: customPickerTheme?.cancelButtonStyle,
                          child: Text(widget.cancelText,
                              style: customPickerTheme?.cancelTextStyle),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              selectedFiles.isNotEmpty
                                  ? selectedFiles
                                      .map((f) => f.mediaFile?.path ?? "")
                                      .toList()
                                  : <String>[],
                            );
                          },
                          style: customPickerTheme?.doneButtonStyle,
                          child: Text(widget.doneText,
                              style: customPickerTheme?.doneTextStyle),
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}
