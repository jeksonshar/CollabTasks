import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as quill;

String deltaJsonToPlainText(String deltaJson) {
  try {
    final doc = quill.Document.fromJson(jsonDecode(deltaJson) as List<dynamic>);
    return doc.toPlainText().trim();
  } catch (_) {
    return deltaJson;
  }
}

quill.Delta trimDelta(quill.Delta delta) {
  final ops = List<Map<String, dynamic>>.from(delta.toJson().cast<Map<String, dynamic>>());

  bool isEmptyTextOp(Map<String, dynamic> op) {
    final insert = op['insert'];
    return insert is String && insert.trim().isEmpty;
  }

  // Remove empty text ops from the edges
  while (ops.isNotEmpty && isEmptyTextOp(ops.first)) {
    ops.removeAt(0);
  }
  while (ops.isNotEmpty && isEmptyTextOp(ops.last)) {
    ops.removeLast();
  }

  // Trim the edge lines if they contain spaces/newlines
  if (ops.isNotEmpty && ops.first['insert'] is String) {
    ops.first['insert'] = (ops.first['insert'] as String).replaceFirst(RegExp(r'^\s+'), '');
    if ((ops.first['insert'] as String).isEmpty) {
      ops.removeAt(0);
    }
  }

  if (ops.isNotEmpty && ops.last['insert'] is String) {
    ops.last['insert'] = (ops.last['insert'] as String).replaceFirst(RegExp(r'\s+$'), '');
    if ((ops.last['insert'] as String).isEmpty) {
      ops.removeLast();
    }
  }

  // Quill document must end with a newline
  if (ops.isEmpty) {
    ops.add({'insert': '\n'});
  } else {
    final lastInsert = ops.last['insert'];
    if (lastInsert is String && !lastInsert.endsWith('\n')) {
      ops.add({'insert': '\n'});
    }
  }

  return quill.Delta.fromJson(ops);
}
