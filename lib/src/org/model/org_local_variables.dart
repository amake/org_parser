part of '../model.dart';

class OrgLocalVariables extends OrgLeafNode with OrgElement {
  OrgLocalVariables(
    this.start,
    Iterable<({String prefix, String content, String suffix})> entries,
    this.end,
    this.trailing,
  ) : entries = List.unmodifiable(entries);

  // TODO(aaron): Org Mode just considers this to be a comment (e.g. via
  // `org-element-at-point`). Should we do the same?
  @override
  final elementName = 'comment';

  @override
  final String indent = '';
  final String start;
  final List<({String prefix, String content, String suffix})> entries;
  final String end;
  @override
  final String trailing;

  String get contentString => entries.map((line) => line.content).join('\n');

  @override
  bool contains(Pattern pattern) =>
      start.contains(pattern) ||
      entries.any((line) => line.content.contains(pattern)) ||
      end.contains(pattern) ||
      trailing.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf.write(start);
    for (final entry in entries) {
      buf
        ..write(entry.prefix)
        ..write(entry.content)
        ..write(entry.suffix);
    }
    buf
      ..write(end)
      ..write(trailing);
  }

  @override
  OrgLocalVariables copyWith({
    String? indent, // ignore
    String? start,
    Iterable<({String prefix, String content, String suffix})>? entries,
    String? end,
    String? trailing,
  }) =>
      OrgLocalVariables(
        start ?? this.start,
        entries ?? this.entries,
        end ?? this.end,
        trailing ?? this.trailing,
      );
}
