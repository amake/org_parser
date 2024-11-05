part of '../model.dart';

/// A citation like [cite:@key]
class OrgCitation extends OrgLeafNode {
  String leading;
  ({String leading, String value})? style;
  String delimiter;
  String body;
  String trailing;

  OrgCitation(
    this.leading,
    this.style,
    this.delimiter,
    this.body,
    this.trailing,
  );

  // TODO(aaron): This is dangerously close to needing its own parser
  List<String> getKeys() => body
      .split(';')
      .expand((token) => token.split(' '))
      .expand((token) => token.split(RegExp('(?=@)')))
      .where((token) => token.startsWith('@'))
      .map((token) => token.substring(1))
      .toList(growable: false);

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(style?.leading ?? '')
      ..write(style?.value ?? '')
      ..write(delimiter)
      ..write(body)
      ..write(trailing);
  }

  @override
  bool contains(Pattern pattern) {
    return leading.contains(pattern) ||
        style?.value.contains(pattern) == true ||
        delimiter.contains(pattern) ||
        body.contains(pattern) ||
        trailing.contains(pattern);
  }

  OrgCitation copyWith({
    String? leading,
    ({String leading, String value})? style,
    String? delimiter,
    String? body,
    String? trailing,
  }) {
    return OrgCitation(
      leading ?? this.leading,
      style ?? this.style,
      delimiter ?? this.delimiter,
      body ?? this.body,
      trailing ?? this.trailing,
    );
  }
}
