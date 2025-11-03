enum Difficulty {
  trivial,
  easy,
  medium,
  hard,
  impossible;

  static Difficulty? fromString(String? t) {
    if (t == null) {
      return null;
    }

    switch (t.toLowerCase()) {
      case 'trivial':
        return Difficulty.trivial;
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      case 'impossible':
        return Difficulty.impossible;
      default:
        return null;
    }
  }

  static Difficulty max(Difficulty lhs, Difficulty rhs) {
    if (lhs.index > rhs.index) {
      return lhs;
    }

    return rhs;
  }

  @override
  String toString() {
    final label = name;
    if (label.isEmpty) {
      return label;
    }
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }
}
