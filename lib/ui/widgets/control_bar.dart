import 'package:auto_sudoku/ui/widgets/action_bar.dart';
import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActionBar(),
        //const SizedBox(height: 20), const NumberPad()
      ],
    );
  }
}
