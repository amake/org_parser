part of '../model.dart';

/// Supported styles for [OrgMarkup] nodes
enum OrgStyle {
  bold,
  verbatim,
  italic,
  strikeThrough,
  underline,
  code,
}

/// Emphasis markup, like
/// ```
/// *bold*
/// /italic/
/// +strikethrough+
/// ~code~
/// =verbatim=
/// ```
///
/// See [OrgStyle] for supported emphasis types
class OrgMarkup extends OrgLeafNode {
  // TODO(aaron): Get rid of this hack
  OrgMarkup.just(String content, OrgStyle style) : this('', content, '', style);

  OrgMarkup(
    this.leadingDecoration,
    this.content,
    this.trailingDecoration,
    this.style,
  );

  final String leadingDecoration;
  final String content;
  final String trailingDecoration;
  final OrgStyle style;

  @override
  String toString() => 'OrgMarkup';

  @override
  bool contains(Pattern pattern) =>
      leadingDecoration.contains(pattern) ||
      content.contains(pattern) ||
      trailingDecoration.contains(pattern);

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leadingDecoration)
      ..write(content)
      ..write(trailingDecoration);
  }
}
