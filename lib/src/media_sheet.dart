import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'package:skeletonizer/skeletonizer.dart';



import 'loading_status.dart';
import 'media_controller.dart';
import 'media_manager.dart';
import 'media_tile.dart';

Future<List<MediaViewModel>?> showGridBottomSheet(BuildContext context, int maxLimit) {
  var controller = Get.find<MediaPickerController>();
  return showModalBottomSheet<List<MediaViewModel>?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(
                        () => Row(
                      children: List.generate(
                          controller.mediaFoldersStream.length, (index) {
                        return InkWell(
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () async {
                            if (controller.loadStatus.value !=
                                LoadStatus.loading) {
                              await controller.fetchMediaOfAlbum(index);
                            }else{
                              print("loading");
                            }
                          },
                          child: Skeletonizer(
                            enabled: controller.loadStatus.value ==
                                LoadStatus.loading && controller
                                .mediaFoldersStream.isEmpty,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: controller.tabIndexStream.value ==
                                    index
                                    ? Colors.lightBlueAccent
                                    .withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(controller
                                  .mediaFoldersStream[index].name),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // GridView for Media Files
                Expanded(
                  child: Obx(
                        () => Skeletonizer(
                      enabled: controller.loadStatus.value ==
                          LoadStatus.loading,
                      child: GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: controller.mediaFilesStream.length,
                        controller: controller.scrollController,
                        itemBuilder: (context, index) {
                          return MediaTile(
                            media: controller.mediaFilesStream[index],
                            onThumbnailLoad: (thumb) {
                              controller.mediaFilesStream[index].thumbnail = thumb;
                              setState(() {});
                            },
                            onSelected: (media) async {
                              controller.onFileSelect(controller.mediaFilesStream[index]);
                              if (maxLimit == 1) {
                                Navigator.pop(
                                    context,
                                    [controller
                                        .selectedFile[index]]);
                            }
                            },
                            isSelected: controller.selectedFile.any((t)=>t.id == controller.mediaFilesStream[index].id),
                            selectionIndex: controller.getSelectionIndex(controller.mediaFilesStream[index]),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          Navigator.pop(context, null);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Cancel",
                            style:
                            TextStyle(color: Colors.lightBlueAccent),
                          ),
                        )),
                    InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () async {
                          Navigator.pop(
                              context,
                              controller.selectedFile.isNotEmpty
                                  ? controller.selectedFile
                                  : null);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Done",
                            style:
                            TextStyle(color: Colors.lightBlueAccent),
                          ),
                        )),
                  ],
                )
              ],
            ),
          );
        },
      );
    },
  );
}

