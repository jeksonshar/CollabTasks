import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditorVisibilityController {
  final ScrollController dialogScrollController;
  final GlobalKey editorKey;
  final quill.QuillController controller;
  final double extraPadding;

  const EditorVisibilityController({
    required this.dialogScrollController,
    required this.editorKey,
    required this.controller,
    required this.extraPadding,
  });

  Future<void> ensureVisible(BuildContext context, {bool isNeedDelay = false}) async {
    if (!dialogScrollController.hasClients) return;
    if (editorKey.currentContext == null) return;

    if (isNeedDelay) {
      const Duration attemptDelay = Duration(milliseconds: 100);
      await Future<void>.delayed(attemptDelay);
    }

    if (!context.mounted) return;

    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final screenHeight = media.size.height;
    final bottomSafeArea = media.viewPadding.bottom;
    final topSafeArea = media.viewPadding.top;
    final visibleBottom = screenHeight - keyboardInset - bottomSafeArea;
    final visibleTop =
        topSafeArea; // TODO проверить правильность этого параметра и расчеты с ним далее в _isCaretVisible()

    try {
      final renderBox = editorKey.currentContext!.findRenderObject() as RenderBox;
      final editorTopLeftGlobal = renderBox.localToGlobal(Offset.zero);
      final editorBottomGlobal = editorTopLeftGlobal.dy + renderBox.size.height + extraPadding;

      if (_isCaretVisible(visibleTop, visibleBottom)) {
        debugPrint('_isCaretVisible() return true');
        debugPrint('-----------------------------');
        return;
      }

      double diff = 0;
      if (editorBottomGlobal > visibleBottom) {
        diff = editorBottomGlobal - visibleBottom;
      }
      /* TODO без элса ниже работает когда каретка в конце текста, но не работает когда ставим ее в
           середину текста, т.к при попытке его туда поставить происходит скролл в самый конец
           (иногда и каретка устанавливается в конец) , проверить расчеты, с ними что то не так
      */
      // else {
      //   final visibleHeight = screenHeight - keyboardInset - editorBottomGlobal;
      //   diff = editorBottomGlobal - visibleHeight;
      // }

      debugPrint('_isCaretVisible() return false');
      debugPrint(
        'editorBottomGlobal = $editorBottomGlobal, visibleBottom = $visibleBottom, visibleTop = $visibleTop',
      );
      debugPrint('dialogScrollController.offset = ${dialogScrollController.offset}, diff = $diff');
      debugPrint('-----------------------------------');

      final target = (dialogScrollController.offset + diff).clamp(
        0.0,
        dialogScrollController.position.maxScrollExtent,
      );

      await dialogScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('ensureEditorVisible: final fallback failed: $e');
    }
  }

  bool _isCaretVisible(double visibleTop, double visibleBottom, {double padding = 8.0}) {
    final ctx = editorKey.currentContext;
    if (ctx == null) return false;

    final sel = controller.selection;
    if (!sel.isValid) return false;

    final top = visibleTop + padding;
    final bottom = visibleBottom - padding;

    // approximate position estimate by offset / text length
    try {
      final ro = ctx.findRenderObject();
      if (ro is RenderBox) {
        final editorTopGlobal = ro.localToGlobal(Offset.zero).dy + extraPadding;
        final editorHeight = ro.size.height;

        final text = controller.document.toPlainText();
        final docLen = text.isEmpty ? 1 : text.length;
        final selOffset = sel.baseOffset.clamp(0, docLen);
        final ratio = selOffset / docLen;
        final approxCaretYGlobal =
            editorTopGlobal + ratio * editorHeight; // TODO тут проблема, надо переделать

        debugPrint('~~~~~~~~~~~~~~~~~~~~~~~~~~');
        debugPrint('11111 in _isCaretVisible()');
        debugPrint(
          'approxCaretYGlobal = $approxCaretYGlobal, editorTopGlobal = $editorTopGlobal, ratio = $ratio, editorHeight = $editorHeight, top = $top, bottom = $bottom',
        );
        debugPrint('~~~~~~~~~~~~~~~~~~~~~~~~~~');

        return approxCaretYGlobal >= top && approxCaretYGlobal <= bottom;
      }
    } catch (e) {
      debugPrint('ensureEditorVisible: isCaretVisible failed: $e');
    }

    return false;
  }
}
