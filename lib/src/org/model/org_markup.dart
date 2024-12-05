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
class OrgMarkup extends OrgParentNode {
  // TODO(aaron): Get rid of this hack
  OrgMarkup.just(String content, OrgStyle style)
      : this('', OrgContent([OrgPlainText(content)]), '', style);

  OrgMarkup(
    this.leadingDecoration,
    this.content,
    this.trailingDecoration,
    this.style, [
    super.id,
  ]);

  final String leadingDecoration;
  final OrgContent content;
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
      ..visit(content)
      ..write(trailingDecoration);
  }

  @override
  List<OrgNode> get children => [content];

  @override
  OrgMarkup fromChildren(List<OrgNode> children) =>
      copyWith(content: children.single as OrgContent);

  OrgMarkup copyWith({
    String? leadingDecoration,
    OrgContent? content,
    String? trailingDecoration,
    OrgStyle? style,
    String? id,
  }) =>
      OrgMarkup(
        leadingDecoration ?? this.leadingDecoration,
        content ?? this.content,
        trailingDecoration ?? this.trailingDecoration,
        style ?? this.style,
        id ?? this.id,
      );
}
