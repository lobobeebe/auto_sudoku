import 'package:flutter/material.dart';

class CellViewModel {
  final Color? backgroundColor;
  final Color? valueTextColor;
  final FontWeight? valueFontWeight;
  final double? valueScale;
  final List<CellNoteViewModel> notes;

  CellViewModel({
    this.backgroundColor,
    this.valueTextColor,
    this.valueFontWeight,
    this.valueScale,
    required this.notes,
  });
}

class CellNoteViewModel {
  final Color? textColor;
  final double? scale;
  final FontWeight? fontWeight;

  CellNoteViewModel({this.textColor, this.scale, required this.fontWeight});
}
