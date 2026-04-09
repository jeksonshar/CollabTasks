import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;

String deltaJsonToPlainText(String deltaJson) {
  try {
    final doc = quill.Document.fromJson(jsonDecode(deltaJson) as List<dynamic>);
    return doc.toPlainText().trim();
  } catch (_) {
    return deltaJson;
  }
}
