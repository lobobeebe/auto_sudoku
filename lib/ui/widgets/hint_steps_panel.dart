import 'package:auto_sudoku/ui/utils/technique_explanation.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

class HintStepsPanel extends StatefulWidget {
  const HintStepsPanel({
    super.key,
    required this.hint,
    required this.onSkip,
    required this.onApply,
  });

  final Hint hint;
  final VoidCallback onSkip;
  final VoidCallback onApply;

  @override
  State<HintStepsPanel> createState() => _HintStepsPanelState();
}

class _HintStepsPanelState extends State<HintStepsPanel> {
  late final PageController _controller;
  late final TechniqueExplanation _explanation;

  @override
  void initState() {
    super.initState();
    _controller = PageController();

    _explanation = explainTechnique(widget.hint);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Removes the outline divider
      ),
      child: Card(
        child: ExpansionTile(
          title: Text(
            _explanation.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          showTrailingIcon: false,
          subtitle: Row(
            spacing: 10,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
              FilledButton(
                onPressed: widget.onApply,
                child: const Text('Apply'),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_explanation.overview),
            ),
          ],
        ),
      ),
    );
  }
}
