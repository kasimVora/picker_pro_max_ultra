import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../media_picker_widget.dart';

class LoadingWidget extends StatelessWidget {
  LoadingWidget({required this.decoration});

  final PickerDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: (decoration.loadingWidget != null)
          ? decoration.loadingWidget
          : SizedBox(
        width: 200.0,
        height: 100.0,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 100.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }
}
