part of '../model.dart';

/// ```
/// #+begin_quote
/// foo
/// #+end_quote
/// ```
///
/// See also [OrgSrcBlock]
class OrgBlock extends OrgParentNode with OrgElement {
  OrgBlock(
    this.type,
    this.indent,
    this.header,
    this.body,
    this.footer,
    this.trailing, [
    super.id,
  ]);

  @override
  final String indent;
  final String header;
  final OrgNode body;
  final String footer;
  @override
  final String trailing;

  /// The kind of block, like `quote`, `example`, etc. Normalized to lower case.
  final String type;

  @override
  List<OrgNode> get children => [body];

  @override
  OrgBlock fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single);

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);

  @override
  String toString() => 'OrgBlock';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(header)
      ..visit(body)
      ..write(footer)
      ..write(trailing);
  }

  OrgBlock copyWith({
    String? type,
    String? indent,
    String? header,
    OrgNode? body,
    String? footer,
    String? trailing,
    String? id,
  }) =>
      OrgBlock(
        type ?? this.type,
        indent ?? this.indent,
        header ?? this.header,
        body ?? this.body,
        footer ?? this.footer,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

/// A source block, like
/// ```
/// #+begin_src sh
///   echo "hello world"
/// #+end_src
/// ```
class OrgSrcBlock extends OrgBlock {
  OrgSrcBlock(
    this.language,
    String indent,
    String header,
    OrgNode body,
    String footer,
    String trailing,
  ) : super('src', indent, header, body, footer, trailing);

  /// The language of the block, like `sh`
  final String? language;
}

/// An inline source block, like `src_sh{echo "hello world"}`
class OrgInlineSrcBlock extends OrgLeafNode {
  OrgInlineSrcBlock(this.leading, this.language, this.arguments, this.body);

  final String leading;
  final String language;
  final String? arguments;
  final String body;

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(language)
      ..write(arguments ?? '')
      ..write(body);
  }

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      language.contains(pattern) ||
      arguments?.contains(pattern) == true ||
      body.contains(pattern);
}
