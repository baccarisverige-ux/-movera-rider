import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps keystrokes typed between tapping a search field and that field being
/// ready to receive them.
///
/// Opening the "Where to?" sheet is not instant: the home sheet expands, a
/// deliberate pause lets that settle, the picker sheet is pushed, and only then
/// does the engine attach the native input behind the field. Anything typed
/// across that window used to be dropped, so tapping and typing straight away
/// lost the opening characters.
///
/// [start] it at the moment of the tap — before any of that sequencing — and
/// the keystrokes are buffered instead. [attach] hands them to the real field
/// once it exists, and the capture steps aside as soon as the field has focus.
class EarlyInputCapture {
  final StringBuffer _pending = StringBuffer();

  TextEditingController? _controller;
  FocusNode? _focusNode;
  bool _started = false;

  /// Called for text the capture applies, so anything the field drives (search
  /// results, validation) stays in step with what is on screen.
  ValueChanged<String>? onChanged;

  void start() {
    if (_started) return;
    _started = true;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    HardwareKeyboard.instance.removeHandler(_onKey);
  }

  /// Point the capture at the real field, handing over anything typed so far.
  void attach(TextEditingController controller, FocusNode focusNode) {
    _controller = controller;
    _focusNode = focusNode;
    if (_pending.isEmpty) return;
    final buffered = _pending.toString();
    _pending.clear();
    _write(controller.text + buffered);
  }

  void _write(String next) {
    final controller = _controller;
    if (controller == null) return;
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    onChanged?.call(next);
  }

  String get _text => _controller?.text ?? _pending.toString();

  void _apply(String next) {
    if (_controller == null) {
      _pending
        ..clear()
        ..write(next);
      return;
    }
    _write(next);
  }

  bool _onKey(KeyEvent event) {
    // Once the field has focus it speaks for itself.
    if (_focusNode?.hasFocus ?? false) return false;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final text = _text;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (text.isNotEmpty) _apply(text.substring(0, text.length - 1));
      return true;
    }

    final character = event.character;
    if (character == null || character.isEmpty) return false;
    // Control characters (enter, tab, escape) are not text.
    if (character.codeUnitAt(0) < 0x20) return false;

    _apply(text + character);
    return true;
  }
}
