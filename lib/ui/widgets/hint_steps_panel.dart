import 'package:flutter/material.dart';

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart' as solver;

class HintStepsPanel extends StatefulWidget {
  const HintStepsPanel({
    super.key,
    required this.hint,
    required this.onSkip,
    required this.onApply,
  });

  final solver.Hint hint;
  final VoidCallback onSkip;
  final VoidCallback onApply;

  @override
  State<HintStepsPanel> createState() => _HintStepsPanelState();
}

class _HintStepsPanelState extends State<HintStepsPanel> {
  late final PageController _controller;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = _buildPages();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              itemBuilder: (context, index) =>
                  _HintPageView(theme: theme, page: pages[index]),
            ),
          ),
          const SizedBox(height: 16),
          _HintDotsIndicator(count: pages.length, index: _pageIndex),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
              FilledButton(
                onPressed: widget.onApply,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_HintPageData> _buildPages() {
    final hint = widget.hint;
    final pages = <_HintPageData>[
      _HintPageData(title: solver.techniqueLabel(hint.technique), lines: []),
    ];

    if (hint.placements.isNotEmpty) {
      final lines = hint.placements.map((entry) {
        final index = entry.$1;
        final digit = entry.$2;
        return 'Place $digit at ${_cellLabel(index)}';
      }).toList();
      pages.add(_HintPageData(title: 'Placements', lines: lines));
    }

    if (hint.eliminations.isNotEmpty) {
      final lines = hint.eliminations.map((entry) {
        final index = entry.$1;
        final digit = entry.$2;
        return 'Remove $digit from ${_cellLabel(index)}';
      }).toList();
      pages.add(_HintPageData(title: 'Eliminations', lines: lines));
    }

    if (hint.cells.isNotEmpty || hint.digits.isNotEmpty) {
      final lines = <String>[];
      if (hint.cells.isNotEmpty) {
        final labels = hint.cells.map(_cellLabel).join(', ');
        lines.add('Cells involved: $labels');
      }
      if (hint.digits.isNotEmpty) {
        lines.add('Digits involved: ${hint.digits.join(', ')}');
      }
      pages.add(_HintPageData(title: 'Pattern', lines: lines));
    }

    return pages;
  }

  String _cellLabel(int index) {
    final row = index ~/ 9 + 1;
    final col = index % 9 + 1;
    return 'r$row c$col';
  }
}

class _HintPageData {
  const _HintPageData({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class _HintPageView extends StatelessWidget {
  const _HintPageView({required this.theme, required this.page});

  final ThemeData theme;
  final _HintPageData page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              page.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...page.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(line, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintDotsIndicator extends StatelessWidget {
  const _HintDotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
