import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';

class LinkPainter extends CustomPainter {
  LinkPainter({
    required this.segments,
    required this.startIndex,
    required this.primaryColor,
    required this.secondaryColor,
    required this.nodeFillColor,
    required this.nodeStrokeColor,
  });

  final List<LinkSegment> segments;
  final int? startIndex;
  final Color primaryColor;
  final Color secondaryColor;
  final Color nodeFillColor;
  final Color nodeStrokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / SudokuBoardState.size;
    final cellHeight = size.height / SudokuBoardState.size;
    final baseCell = math.min(cellWidth, cellHeight);
    final strokeWidth = (cellWidth + cellHeight) * 0.08;
    final accentStroke = strokeWidth + 3;

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = accentStroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.45);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final nodeRadius = strokeWidth * 0.9;
    final haloRadius = nodeRadius * 1.7;
    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.6
      ..color = nodeStrokeColor.withValues(alpha: 0.4);
    final nodePaint = Paint()..style = PaintingStyle.fill;

    final nodes = <int>{};
    if (segments.isNotEmpty) {
      for (final segment in segments) {
        final start = _cellCenter(segment.fromIndex, cellWidth, cellHeight);
        final end = _cellCenter(segment.toIndex, cellWidth, cellHeight);

        final color = segment.usePrimaryColor ? primaryColor : secondaryColor;
        final control = _controlPoint(
          start,
          end,
          baseCell,
          segment.usePrimaryColor,
        );

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

        shadowPaint.color = color.withValues(alpha: 0.22);
        canvas.drawPath(path, shadowPaint);

        linePaint.color = color;
        canvas.drawPath(path, linePaint);

        nodes
          ..add(segment.fromIndex)
          ..add(segment.toIndex);
      }
    }

    for (final index in nodes) {
      final center = _cellCenter(index, cellWidth, cellHeight);
      nodePaint.color = nodeFillColor.withValues(alpha: 0.92);
      canvas.drawCircle(center, nodeRadius, nodePaint);
      canvas.drawCircle(center, haloRadius, haloPaint);
    }

    if (startIndex != null) {
      final center = _cellCenter(startIndex!, cellWidth, cellHeight);
      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.9
        ..color = primaryColor.withValues(alpha: 0.8);
      canvas.drawCircle(center, haloRadius * 1.2, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(LinkPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.startIndex != startIndex ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.nodeFillColor != nodeFillColor ||
        oldDelegate.nodeStrokeColor != nodeStrokeColor;
  }

  Offset _cellCenter(int index, double cellWidth, double cellHeight) {
    final row = index ~/ SudokuBoardState.size;
    final col = index % SudokuBoardState.size;
    return Offset((col + 0.5) * cellWidth, (row + 0.5) * cellHeight);
  }

  Offset _controlPoint(
    Offset start,
    Offset end,
    double cellSize,
    bool usePrimaryColor,
  ) {
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) {
      return mid;
    }
    final normalX = -dy / length;
    final normalY = dx / length;
    final bend = cellSize * 0.35 * (usePrimaryColor ? 1 : -1);
    return Offset(mid.dx + normalX * bend, mid.dy + normalY * bend);
  }
}
