class SudokuUtils {
  static bool notesEqual(Set<int> lhs, Set<int> rhs) {
    if (lhs.length != rhs.length) {
      return false;
    }

    return rhs.containsAll(lhs);
  }
}
