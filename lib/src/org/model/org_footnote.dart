part of '../model.dart';

/// A footnote, like
/// ```
/// [fn:1] this is a footnote
/// ```
class OrgFootnote extends OrgParentNode with OrgElement {
  OrgFootnote(this.marker, this.content, this.trailing, [super.id])
      : assert(marker.isDefinition);

  @override
  final String indent = '';
  final OrgFootnoteReference marker;
  final OrgContent content;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [marker, content];

  @override
  OrgFootnote fromChildren(List<OrgNode> children) => copyWith(
      marker: children[0] as OrgFootnoteReference,
      content: children[1] as OrgContent);

  @override
  bool contains(Pattern pattern) =>
      marker.contains(pattern) || content.contains(pattern);

  @override
  String toString() => 'OrgFootnote';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..visit(marker)
      ..visit(content)
      ..write(trailing);
  }

  OrgFootnote copyWith({
    OrgFootnoteReference? marker,
    OrgContent? content,
    String? trailing,
    String? id,
  }) =>
      OrgFootnote(
        marker ?? this.marker,
        content ?? this.content,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

/// A footnote reference, like `[fn:1]`
class OrgFootnoteReference extends OrgParentNode {
  OrgFootnoteReference.named(
    String leading,
    String name,
    String trailing, [
    String? id,
  ]) : this(false, leading, name, null, trailing, id);

  OrgFootnoteReference(
    this.isDefinition,
    this.leading,
    this.name,
    this.definition,
    this.trailing, [
    super.id,
  ]);

  final bool isDefinition;
  final String leading;
  final String? name;
  final ({String delimiter, OrgContent value})? definition;
  final String trailing;

  @override
  List<OrgNode> get children =>
      definition == null ? const [] : [definition!.value];

  @override
  OrgFootnoteReference fromChildren(List<OrgNode> children) =>
      copyWith(definition: (
        delimiter: definition?.delimiter ?? ':',
        value: children.single as OrgContent,
      ));

  @override
  bool contains(Pattern pattern) {
    final name = this.name;
    final definition = this.definition;
    return leading.contains(pattern) ||
        name?.contains(pattern) == true ||
        definition?.delimiter.contains(pattern) == true ||
        definition?.value.contains(pattern) == true ||
        trailing.contains(pattern);
  }

  @override
  String toString() => 'OrgFootnoteReference';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(name ?? '')
      ..write(definition?.delimiter ?? '');
    if (definition != null) buf.visit(definition!.value);
    buf.write(trailing);
  }

  @override
  void _toPlainTextImpl(OrgSerializer buf) {
    buf
      ..write('[')
      ..write(name ?? '')
      ..write(definition?.delimiter ?? '');
    if (definition != null) buf.visit(definition!.value);
    buf.write(trailing);
  }

  OrgFootnoteReference copyWith({
    bool? isDefinition,
    String? leading,
    String? name,
    ({String delimiter, OrgContent value})? definition,
    String? trailing,
    String? id,
  }) =>
      OrgFootnoteReference(
        isDefinition ?? this.isDefinition,
        leading ?? this.leading,
        name ?? this.name,
        definition ?? this.definition,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}
