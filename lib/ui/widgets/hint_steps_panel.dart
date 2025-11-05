import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:auto_sudoku/ui/utils/technique_explanation.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HintStepsPanel extends StatefulWidget {
  const HintStepsPanel({super.key, required this.hint});

  final Hint hint;

  @override
  State<HintStepsPanel> createState() => _HintStepsPanelState();
}

class _HintStepsPanelState extends State<HintStepsPanel> {
  late final TechniqueExplanation _explanation;

  @override
  void initState() {
    super.initState();

    _explanation = explainTechnique(widget.hint);
  }

  @override
  Widget build(BuildContext context) {
    final board = Provider.of<SudokuBoardState>(context, listen: false);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Removes the outline divider
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 10,
            children: [
              Icon(Icons.auto_awesome_motion_rounded),
              Expanded(
                child: Text(
                  _explanation.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => board.requestClearHint(),
                icon: const Icon(Icons.close),
              ),
              IconButton.filled(
                onPressed: () {
                  final applied = board.requestApplyCurrentHint();
                  if (!applied) {
                    showFeedback(context, 'Unable to apply hint.');
                  }
                },
                icon: const Icon(Icons.check),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
