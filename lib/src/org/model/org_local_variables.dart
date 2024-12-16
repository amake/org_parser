part of '../model.dart';

class OrgLocalVariables extends OrgLeafNode with OrgElement {
  OrgLocalVariables(
    this.start,
    Iterable<({String prefix, String content, String suffix})> content,
    this.end,
    this.trailing,
  ) : entries = List.unmodifiable(content);

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
}
