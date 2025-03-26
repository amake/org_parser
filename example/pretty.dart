import 'dart:convert';
import 'dart:io';

import 'package:org_parser/org_parser.dart';

void main(List<String> arguments) async {
  final markup = arguments.isNotEmpty
      ? arguments.first
      : await stdin.transform(utf8.decoder).join();
  final doc = OrgDocument.parse(markup);
  visit(doc);
}

void visit(OrgNode node, {int depth = 0}) {
  final preview = makePreview(node);
  print('${'  ' * depth}$node: $preview');
  if (node is OrgParentNode) {
    for (final child in node.children) {
      visit(child, depth: depth + 1);
    }
  }
}

String makePreview(OrgNode node) {
  final result =
      node.toMarkup(serializer: PreviewSerializer()).replaceAll('\n', r'\n');
  if (result.trim().isEmpty) return '"$result"';
  return result;
}

const previewLength = 10;

class PreviewSerializer extends OrgSerializer {
  var _canceled = false;

  void cancel() => _canceled = true;

  @override
  void write(String text) {
    if (_canceled) return;
    super.write(text);
    if (length >= previewLength) cancel();
  }

  @override
  void visit(OrgNode node) {
    if (_canceled) return;
    super.visit(node);
  }

  @override
  String toString() {
    final result = super.toString();
    if (result.length <= previewLength) return result;
    return '${result.substring(0, previewLength)}...';
  }
}
