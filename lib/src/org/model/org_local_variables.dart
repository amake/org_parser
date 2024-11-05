part of '../model.dart';

class OrgLocalVariables extends OrgLeafNode {
  OrgLocalVariables(
    this.start,
    Iterable<({String prefix, String content, String suffix})> content,
    this.end,
  ) : entries = List.unmodifiable(content);

  final String start;
  final List<({String prefix, String content, String suffix})> entries;
  final String end;

  String get contentString => entries.map((line) => line.content).join('\n');

  @override
  bool contains(Pattern pattern) =>
      start.contains(pattern) ||
      entries.any((line) => line.content.contains(pattern)) ||
      end.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf.write(start);
    for (final entry in entries) {
      buf
        ..write(entry.prefix)
        ..write(entry.content)
        ..write(entry.suffix);
    }
    buf.write(end);
  }
}
