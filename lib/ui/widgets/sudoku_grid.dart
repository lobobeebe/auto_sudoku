import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/state/cell_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:provider/provider.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final board = Provider.of<SudokuBoardState>(context);
    final theme = SudokuTheme.of(context);

    return Center(
      child: AspectRatio(
        aspectRatio: 1, // enforce a perfect square
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final grid = SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: List.generate(SudokuBoardState.size, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(SudokuBoardState.size, (col) {
                          final index = row * SudokuBoardState.size + col;

                          final cellVM = board.buildCellViewModel(index, theme);
                          final background = cellVM.backgroundColor;

                          final borderColor = colorScheme.outlineVariant;
                          final border = Border(
                            top: BorderSide(
                              color: borderColor,
                              width: row == 0 ? 2 : (row % 3 == 0 ? 1.5 : 0.5),
                            ),
                            left: BorderSide(
                              color: borderColor,
                              width: col == 0 ? 2 : (col % 3 == 0 ? 1.5 : 0.5),
                            ),
                            right: BorderSide(
                              color: borderColor,
                              width: col == SudokuBoardState.size - 1
                                  ? 2
                                  : ((col + 1) % 3 == 0 ? 1.5 : 0.5),
                            ),
                            bottom: BorderSide(
                              color: borderColor,
                              width: row == SudokuBoardState.size - 1
                                  ? 2
                                  : ((row + 1) % 3 == 0 ? 1.5 : 0.5),
                            ),
                          );

                          final cellState = board.cellAt(index);

                          return Expanded(
                            child: ChangeNotifierProvider<CellState>.value(
                              value: cellState,
                              child: GestureDetector(
                                onTap: () => board.requestSelectCell(row, col),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: background,
                                    border: border,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: SudokuCell(
                                      index: index,
                                      viewModel: cellVM,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              );

              return grid;
            },
          ),
        ),
      ),
    );
  }
}

class SudokuCell extends StatelessWidget {
  final int index;
  final CellViewModel viewModel;

  const SudokuCell({super.key, required this.index, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final board = Provider.of<SudokuBoardState>(context, listen: false);
    final value = context.select<CellState, int>((c) => c.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (value != 0) {
          final fontSize = constraints.maxHeight * 0.65;
          return _AnimatedCellValue(
            digit: value,
            fontSize: fontSize,
            color: viewModel.valueTextColor,
            fontWeight: viewModel.valueFontWeight,
          );
        }
        if (board.showNotes) {
          return CellNotesWidget(index: index, viewModel: viewModel);
        }

        return SizedBox.expand();
      },
    );
  }
}

class CellNotesWidget extends StatelessWidget {
  final int index;
  final CellViewModel viewModel;

  const CellNotesWidget({
    super.key,
    required this.index,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final board = Provider.of<SudokuBoardState>(context, listen: false);
    final digits = List<int>.generate(9, (i) => i + 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 3;
        final cellHeight = constraints.maxHeight / 3;
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: List.generate(3, (row) {
            return SizedBox(
              height: cellHeight,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: List.generate(3, (col) {
                  final sub = row * 3 + col;
                  final digit = digits[sub];
                  return Selector<CellState, bool>(
                    selector: (_, cell) => cell.hasNote(digit),
                    shouldRebuild: (prev, next) => prev != next,
                    builder: (_, isActive, __) {
                      return _CellNote(
                        key: ValueKey('note-${index}-${digit}'),
                        index: sub,
                        width: cellWidth,
                        height: cellHeight,
                        isActive: isActive,
                        viewModel: viewModel.notes[sub],
                        state: board,
                        digit: digit,
                      );
                    },
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AnimatedCellValue extends StatefulWidget {
  final int digit;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  const _AnimatedCellValue({
    required this.digit,
    required this.fontSize,
    this.color,
    this.fontWeight,
  });

  @override
  State<_AnimatedCellValue> createState() => _AnimatedCellValueState();
}

class _AnimatedCellValueState extends State<_AnimatedCellValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
    // Animate on first paint to visualize newly placed values
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _AnimatedCellValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger entrance when the digit changes (e.g., from 0 -> x or replacing value)
    if (oldWidget.digit != widget.digit) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          // Faint green flash overlay (like notes) that fades quickly
          final flashOpacity = (1.0 - _fade.value); // subtle

          return Stack(
            alignment: Alignment.center,
            children: [
              if (flashOpacity > 0.001)
                Opacity(
                  opacity: flashOpacity,
                  child: Transform.scale(
                    scale: 1.0 + 0.25 * _scale.value,
                    child: Text(
                      '${widget.digit}',
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: 0.9 + 0.1 * _scale.value,
                  child: Text(
                    '${widget.digit}',
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      color: widget.color,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CellNote extends StatefulWidget {
  final int index;
  final int? digit;
  final bool isActive;
  final SudokuBoardState state;
  final double width;
  final double height;
  final CellNoteViewModel viewModel;
  const _CellNote({
    super.key,
    required this.index,
    required this.digit,
    required this.isActive,
    required this.state,
    required this.width,
    required this.height,
    required this.viewModel,
  });

  @override
  State<_CellNote> createState() => _CellNoteState();
}

// Describes the kind of burst animation currently playing.
enum _BurstKind { none, add, remove }

class _CellNoteState extends State<_CellNote>
    with SingleTickerProviderStateMixin {
  _BurstKind _burstKind = _BurstKind.none;

  late final AnimationController _burstCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _showBurst = false; // only paint burst while animating

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scale = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(
      parent: _burstCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _burstCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _burstKind = _BurstKind.none;
            _showBurst = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CellNote oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger burst whenever the isActive flag flips (robust across rebuilds and key reuse)
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _triggerBurst(_BurstKind.add); // note added → green
      } else {
        _triggerBurst(_BurstKind.remove); // note removed → red
      }
    }
  }

  void _triggerBurst(_BurstKind kind) {
    setState(() {
      _burstCtrl.forward(from: 0);
      _burstKind = kind;
      _showBurst = true;
    });
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error; // red burst color
    final success = Colors.green; // used for green burst

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Active note text (scales via viewModel)
          if (widget.isActive)
            Text(
              "${widget.digit ?? ""}",
              key: const ValueKey('active'),
              style: TextStyle(
                fontSize: (widget.viewModel.scale ?? 1) * 10,
                color: widget.viewModel.textColor,
                fontWeight: widget.viewModel.fontWeight,
                height: .5,
              ),
            )
          else
            const SizedBox.expand(key: ValueKey('inactive')),

          // Optional: flash the digit in red or green during the burst for clarity
          if (_showBurst && widget.digit != null)
            AnimatedBuilder(
              animation: _burstCtrl,
              builder: (context, _) {
                final color = _burstKind == _BurstKind.add ? success : error;
                return Opacity(
                  opacity: 1.0 - _fade.value,
                  child: Transform.scale(
                    scale: 1.0 + 0.3 * _scale.value,
                    child: Text(
                      "${widget.digit}",
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w700,
                        height: .5,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
