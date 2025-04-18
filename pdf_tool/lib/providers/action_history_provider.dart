// Action history provider for undo/redo
import 'package:flutter_riverpod/flutter_riverpod.dart';

final actionHistoryProvider =
    StateNotifierProvider<ActionHistoryNotifier, List<String>>((ref) {
      return ActionHistoryNotifier();
    });

class ActionHistoryNotifier extends StateNotifier<List<String>> {
  ActionHistoryNotifier() : super([]);
  int _currentIndex = -1;

  void addAction(String action) {
    state = state.sublist(0, _currentIndex + 1);
    state = [...state, action];
    _currentIndex++;
  }

  void undo() {
    if (_currentIndex >= 0) {
      _currentIndex--;
      // Notify listeners (UI will handle the undo logic)
    }
  }

  void redo() {
    if (_currentIndex < state.length - 1) {
      _currentIndex++;
      // Notify listeners (UI will handle the redo logic)
    }
  }

  bool get canUndo => _currentIndex >= 0;
  bool get canRedo => _currentIndex < state.length - 1;
}
