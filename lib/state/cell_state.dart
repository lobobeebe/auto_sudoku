import 'package:flutter/material.dart';

class CellState extends ChangeNotifier {
  int _value = 0;
  int _notesMask = 0; // faster than Set<int>

  int get value => _value;
  int get notesMask => _notesMask;
  bool hasNote(int d) => (_notesMask & (1 << (d - 1))) != 0;

  void set(int v, int mask) {
    if (v == _value && mask == _notesMask) return;

    _value = v;
    _notesMask = mask;
    notifyListeners();
  }

  void setValue(int v) {
    set(v, _notesMask);
  }

  void setNote(int d, bool on) {
    final bit = 1 << (d - 1);
    final next = on ? (_notesMask | bit) : (_notesMask & ~bit);
    setNotes(next);
  }

  void setNotes(int mask) {
    set(_value, mask);
  }
}
