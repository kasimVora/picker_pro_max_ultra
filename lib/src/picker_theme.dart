import 'dart:ui';

import 'package:flutter/material.dart';

/// A custom theme extension for the media picker widget.
///
/// This allows customization of various visual aspects of the picker while
/// maintaining consistency with the app's theme system.
@immutable
class PickerThemeData extends ThemeExtension<PickerThemeData> {
  /// Background color of the bottom sheet that contains the media picker.
  final Color? bottomSheetBackgroundColor;

  /// Color of the drag indicator at the top of the bottom sheet.
  final Color? bottomSheetIndicatorColor;

  /// Color used for enabled/active tabs in the media picker.
  final Color? tabEnableColor;

  /// Color used for disabled/inactive tabs in the media picker.
  final Color? tabDisableColor;

  /// Color used for disabled tabs border in the media picker.
  final Color? tabBorderColor;

  /// Text style for the "Done" button text.
  final TextStyle? doneTextStyle;

  /// Text style for the "Cancel" button text.
  final TextStyle? cancelTextStyle;

  /// Border radius for the bottom sheet corners.
  final double? borderRadius;

  /// Button style for the cancel button.
  final ButtonStyle? cancelButtonStyle;

  /// Button style for the done button.
  final ButtonStyle? doneButtonStyle;

  /// Creates a theme for the media picker widget.
  ///
  /// All parameters are optional and will fall back to default theme values
  /// when not specified.
  const PickerThemeData({
    this.bottomSheetBackgroundColor,
    this.bottomSheetIndicatorColor,
    this.tabEnableColor,
    this.tabDisableColor,
    this.doneTextStyle,
    this.cancelTextStyle,
    this.cancelButtonStyle,
    this.doneButtonStyle,
    this.borderRadius,
    this.tabBorderColor,
  });

  @override
  PickerThemeData copyWith({
    Color? backgroundColor,
    Color? bottomSheetBackgroundColor,
    Color? tabBorderColor,
    Color? tabEnableColor,
    Color? tabDisableColor,
    TextStyle? doneTextStyle,
    TextStyle? cancelTextStyle,
    double? borderRadius,
    ButtonStyle? doneButtonStyle,
    ButtonStyle? cancelButtonStyle,
  }) {
    return PickerThemeData(
      bottomSheetBackgroundColor:
          backgroundColor ?? this.bottomSheetBackgroundColor,
      bottomSheetIndicatorColor:
          bottomSheetBackgroundColor ?? bottomSheetIndicatorColor,
      tabEnableColor: tabEnableColor ?? this.tabEnableColor,
      tabDisableColor: tabDisableColor ?? this.tabDisableColor,
      doneTextStyle: doneTextStyle ?? this.doneTextStyle,
      cancelTextStyle: cancelTextStyle ?? this.cancelTextStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      cancelButtonStyle: cancelButtonStyle ?? this.cancelButtonStyle,
      doneButtonStyle: doneButtonStyle ?? this.doneButtonStyle,
      tabBorderColor: tabBorderColor ?? this.tabBorderColor,
    );
  }

  @override
  PickerThemeData lerp(ThemeExtension<PickerThemeData>? other, double t) {
    if (other is! PickerThemeData) return this;
    return PickerThemeData(
      bottomSheetBackgroundColor: Color.lerp(
          bottomSheetBackgroundColor, other.bottomSheetBackgroundColor, t),
      tabDisableColor: Color.lerp(tabDisableColor, other.tabDisableColor, t),
      tabBorderColor: Color.lerp(tabBorderColor, other.tabBorderColor, t),
      tabEnableColor: Color.lerp(tabEnableColor, other.tabEnableColor, t),
      bottomSheetIndicatorColor: Color.lerp(
          bottomSheetIndicatorColor, other.bottomSheetIndicatorColor, t),
      cancelTextStyle:
          TextStyle.lerp(cancelTextStyle, other.cancelTextStyle, t),
      doneTextStyle: TextStyle.lerp(doneTextStyle, other.doneTextStyle, t),
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t),
      cancelButtonStyle:
          ButtonStyle.lerp(cancelButtonStyle, other.cancelButtonStyle, t),
      doneButtonStyle:
          ButtonStyle.lerp(doneButtonStyle, other.doneButtonStyle, t),
    );
  }
}
