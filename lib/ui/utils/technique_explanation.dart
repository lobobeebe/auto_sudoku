import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

/// A user-facing explanation with a brief overview and simple steps.
class TechniqueExplanation {
  final String title;
  final String overview;
  final List<String> steps;
  const TechniqueExplanation({
    required this.title,
    required this.overview,
    required this.steps,
  });
}

/// techniqueKey (supported):
///   Naked:
///     'nakedPairRow'|'nakedPairCol'|'nakedPairBox'
///     'nakedTripleRow'|'nakedTripleCol'|'nakedTripleBox'
///     'nakedQuadRow'|'nakedQuadCol'|'nakedQuadBox'
///   Hidden:
///     'hiddenPairRow'|'hiddenPairCol'|'hiddenPairBox'
///     'hiddenTripleRow'|'hiddenTripleCol'|'hiddenTripleBox'
///     'hiddenQuadRow'|'hiddenQuadCol'|'hiddenQuadBox'
///   Locked:
///     'pointingRow'|'pointingCol'|'claimingRow'|'claimingCol'
///   Medium:
///     'xWingRows'|'xWingCols'|'xyWing'
TechniqueExplanation explainTechnique(Hint hint) {
  String join(List<int> d) => d.join(', ');
  final plural = hint.digits.length > 1;
  final digit = plural ? 'digits' : 'digit';
  final those = plural ? 'those' : 'that';
  final them = plural ? 'them' : 'it';
  final number = join(hint.digits);

  try {
    switch (hint.technique) {
      // ------------------------ NAKED ------------------------

      case StrategyUsed.nakedPair:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Naked Pair (Row)',
              overview:
                  'Two cells in this row have exactly the same two $digit ($number). '
                  'Remove $those $digit from every other cell in the row.',
              steps: [
                'Scan the row and note candidates for each empty cell.',
                'Find two cells whose candidate lists are exactly {$number}.',
                'Because these two cells must take these $digit, remove $them from the other cells in the row.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Naked Pair (Column)',
              overview:
                  'Two cells in this column have exactly the same two $digit ($number). '
                  'Remove $those $digit from the rest of the column.',
              steps: [
                'Scan the column and list candidates.',
                'Identify two cells with candidates {$number} and no others.',
                'Eliminate $them from all other cells in the column.',
              ],
            );
          case HintUnit.box:
            return TechniqueExplanation(
              title: 'Naked Pair (Box)',
              overview:
                  'Two cells in this 3×3 box share the exact two $digit ($number). '
                  'Remove $them from the other cells in the box.',
              steps: [
                'Scan the 3×3 box and list candidates.',
                'Find two cells whose candidates are exactly {$number}.',
                'Delete $them from the remaining cells in the box.',
              ],
            );
          default:
            throw ArgumentError("Naked Pair require a 'HintUnit'");
        }

      case StrategyUsed.nakedTriple:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Naked Triple (Row)',
              overview:
                  'Three cells in this row contain only three $digit ($number) among them. '
                  'Remove $them from all other cells in the row.',
              steps: [
                'List candidates in the row.',
                'Find three cells whose combined candidates are exactly {$number}.',
                'Eliminate $them from other cells in the row.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Naked Triple (Column)',
              overview:
                  'Three cells in this column contain only three $digit ($number). '
                  'Remove $them from the remaining column cells.',
              steps: [
                'List candidates in the column.',
                'Locate three cells whose union of candidates is {$number}.',
                'Delete $them from all other cells in the column.',
              ],
            );
          case HintUnit.box:
            return TechniqueExplanation(
              title: 'Naked Triple (Box)',
              overview:
                  'Three cells in this box contain only the $digit ($number). '
                  'Remove $them from the rest of the box.',
              steps: [
                'List candidates in the box.',
                'Find three cells whose combined candidates are {$number}.',
                'Eliminate $them from other cells in the box.',
              ],
            );
          default:
            throw ArgumentError("Naked Triples require a 'HintUnit'");
        }

      case StrategyUsed.nakedQuad:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Naked Quad (Row)',
              overview:
                  'Four cells in this row hold exactly four $digit ($number). '
                  'Remove $them from the other cells in the row.',
              steps: [
                'List candidates in the row.',
                'Identify four cells whose union is {$number} and each cell contains only these.',
                'Clear $them from the rest of the row.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Naked Quad (Column)',
              overview:
                  'Four cells in this column hold exactly four $digit ($number). '
                  'Remove $them from the remaining column cells.',
              steps: [
                'List candidates in the column.',
                'Find four cells whose combined candidates are {$number}.',
                'Remove $them from other cells in the column.',
              ],
            );
          case HintUnit.box:
            return TechniqueExplanation(
              title: 'Naked Quad (Box)',
              overview:
                  'Four cells in this box contain only four $digit ($number). '
                  'Remove $them from the other box cells.',
              steps: [
                'List candidates in the 3×3 box.',
                'Locate four cells whose union is {$number}.',
                'Delete $them elsewhere in the box.',
              ],
            );
          default:
            throw ArgumentError("Naked Quads require a 'HintUnit'");
        }

      // ------------------------ HIDDEN ------------------------

      case StrategyUsed.hiddenPair:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Hidden Pair (Row)',
              overview:
                  'Within this row, the $digit ($number) each appear only twice as candidates. '
                  'Those two cells must contain them; clear the other candidates in those cells.',
              steps: [
                'Count where each $digit appears as a candidate in the row.',
                'Find two $digit that occur in exactly two cells — the same two positions.',
                'In those two cells, keep only {$number} and remove other candidates.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Hidden Pair (Column)',
              overview:
                  'In this column, the $digit ($number) appear in exactly two cells. '
                  'Those cells must take $them; remove other candidates there.',
              steps: [
                'Count candidate occurrences per digit in the column.',
                'Identify two digits that appear in exactly the same two cells.',
                'Restrict those two cells to {$number} only.',
              ],
            );
          case HintUnit.box:
            return TechniqueExplanation(
              title: 'Hidden Pair (Box)',
              overview:
                  'In this box, the $digit ($number) appear in exactly two cells. '
                  'Those cells must contain $them; clear other candidates.',
              steps: [
                'Count occurrences of each digit in the 3×3 box.',
                'Find two digits limited to the same two cells.',
                'Keep only {$number} in those two cells.',
              ],
            );
          default:
            throw ArgumentError("Hidden Pairs require a 'HintUnit'");
        }

      case StrategyUsed.hiddenTriple:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Hidden Triple (Row)',
              overview:
                  'Three $digit ($number) each occur only three times in this row — in the same three cells. '
                  'Keep only $them in those cells.',
              steps: [
                'Count candidate locations per digit in the row.',
                'Find three digits limited to the same three cells.',
                'In those three cells, keep only {$number}.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Hidden Triple (Column)',
              overview:
                  'Three $digit ($number) each occur only three times in this column — in the same three cells. '
                  'Keep only $them there.',
              steps: [
                'Count candidates per digit in the column.',
                'Find three digits confined to the same three cells.',
                'Limit those cells to {$number}.',
              ],
            );
          case HintUnit.box:
            return TechniqueExplanation(
              title: 'Hidden Triple (Box)',
              overview:
                  'Three $digit ($number) each occur only three times in this box — and only in the same three cells. '
                  'Keep only $them there.',
              steps: [
                'Count candidates per digit in the box.',
                'Find three digits that appear only in the same three cells.',
                'Keep only {$number} in those cells.',
              ],
            );
          default:
            throw ArgumentError("Hidden Triples require a 'HintUnit'");
        }

      case StrategyUsed.hiddenQuad:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Hidden Quad (Row)',
              overview:
                  'Four $digit ($number) each occur only four times in this row — all in the same four cells. '
                  'Keep only $them in those cells.',
              steps: [
                'Count candidate positions per digit across the row.',
                'Find four digits confined to the same four cells.',
                'Restrict those cells to {$number} only.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Hidden Quad (Column)',
              overview:
                  'Four $digit ($number) each occur only four times in this column — in the same four cells. '
                  'Keep only $them there.',
              steps: [
                'Count candidates per digit in the column.',
                'Locate four digits limited to the same four cells.',
                'Limit those cells to {$number}.',
              ],
            );
          case HintUnit.box:
            return TechniqueExplanation(
              title: 'Hidden Quad (Box)',
              overview:
                  'Four $digit ($number) each occur only four times in this box — and only in the same four cells. '
                  'Keep only $them.',
              steps: [
                'Count candidates per digit in the box.',
                'Find four digits that appear only in the same four cells.',
                'Keep only {$number} in those cells.',
              ],
            );
          default:
            throw ArgumentError("Hidden Quads require a 'HintUnit'");
        }

      // ------------------------ LOCKED ------------------------

      case StrategyUsed.pointing:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Locked Candidates — Pointing (Row)',
              overview:
                  'Inside a box, all candidates for $digit $number lie on a single row. '
                  'Remove $them from the rest of that row outside the box.',
              steps: [
                'Within the 3×3 box, mark cells that contain $digit $number.',
                'Confirm all of those candidates are in the same row.',
                'In that row, eliminate $them from cells outside the box.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Locked Candidates — Pointing (Column)',
              overview:
                  'Inside a box, all candidates for $digit $number lie in one column. '
                  'Remove $them from the rest of that column outside the box.',
              steps: [
                'Within the 3×3 box, mark cells holding candidates $number.',
                'Confirm they are all in the same column.',
                'In that column, eliminate $them from cells outside the box.',
              ],
            );
          default:
            throw ArgumentError("Pointing requires a HintUnit Row/Column");
        }

      case StrategyUsed.claiming:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'Locked Candidates — Claiming (Row)',
              overview:
                  'In a row, all candidates for $digit $number fall inside a single box. '
                  'Remove $them from the other cells of that box.',
              steps: [
                'Across the row, mark where $digit $number appear as candidates.',
                'Verify those candidates are confined to the same 3×3 box.',
                'In that box, remove $them from cells not in the row.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'Locked Candidates — Claiming (Column)',
              overview:
                  'In a column, all candidates for $digit $number fall inside a single box. '
                  'Remove $them from the other cells of that box.',
              steps: [
                'Down the column, mark where $number appear as candidates.',
                'Verify those candidates are confined to one 3×3 box.',
                'In that box, remove $them from cells not in the column.',
              ],
            );
          default:
            throw ArgumentError("Claiming requires a HintUnit Row/Column");
        }

      // ------------------------ MEDIUM ------------------------

      case StrategyUsed.xWing:
        switch (hint.unit) {
          case HintUnit.row:
            return TechniqueExplanation(
              title: 'X-Wing (Row-based)',
              overview:
                  'For $digit $number, two rows each show candidates in exactly the same two columns. '
                  'Remove $them from the other rows in those columns.',
              steps: [
                'Pick a digit and mark its candidate columns for each row.',
                'Find two rows where the candidate columns are exactly the same pair.',
                'In those two columns, eliminate the digit from all other rows.',
              ],
            );
          case HintUnit.column:
            return TechniqueExplanation(
              title: 'X-Wing (Column-based)',
              overview:
                  'For $digit $number, two columns each show candidates in the same two rows. '
                  'Remove $them from the other columns in those rows.',
              steps: [
                'Pick a digit and mark its candidate rows for each column.',
                'Find two columns where the candidate rows are the same pair.',
                'In those two rows, eliminate the digit from all other columns.',
              ],
            );
          default:
            throw ArgumentError("X-Wing requires a HintUnit Row/Column");
        }

      case StrategyUsed.xyWing:
        return TechniqueExplanation(
          title: 'XY-Wing',
          overview:
              'An XY-Wing uses three bi-value cells. The pivot is a cell with exactly two candidates {X,Y}. '
              'It sees two wing cells {X,Z} and {Y,Z}. Because the pivot links X to one wing and Y to the other, '
              'any cell that sees both wings cannot be Z.',
          steps: [
            'Find a bi-value pivot cell with exactly two candidates {X,Y} (a bi-value cell has two candidates).',
            'Locate two bi-value wing cells {X,Z} and {Y,Z} that each share a unit (row/column/box) with the pivot.',
            'Identify cells that see both wings and remove Z from those cells.',
          ],
        );
      default:
    }
  } on Error {
    // Do nothing
  }

  return TechniqueExplanation(
    title: 'Technique',
    overview: 'Technique explanation unavailable.',
    steps: const ['No steps available.'],
  );
}
