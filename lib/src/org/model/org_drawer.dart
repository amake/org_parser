part of '../model.dart';

/// A drawer, like
/// ```
/// :PROPERTIES:
/// :CUSTOM_ID: foobar
/// :END:
/// ```
class OrgDrawer extends OrgParentNode with IndentedElement {
  OrgDrawer(
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

  @override
  List<OrgNode> get children => [body];

  @override
  OrgDrawer fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single);

  /// Get a list of [OrgProperty] nodes contained within this block. Optionally
  /// filter the result to include only properties with the specified [key].
  /// Keys are matched case-insensitively.
  List<OrgProperty> properties({String? key}) {
    final upperKey = key?.toUpperCase();
    final result = <OrgProperty>[];
    visit<OrgProperty>((prop) {
      if (upperKey == null || prop.key.toUpperCase() == upperKey) {
        result.add(prop);
      }
      return true;
    });
    return result;
  }

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);

  @override
  String toString() => 'OrgDrawer';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(header)
      ..visit(body)
      ..write(footer)
      ..write(trailing);
  }

  OrgDrawer copyWith({
    String? indent,
    String? header,
    OrgNode? body,
    String? footer,
    String? trailing,
    String? id,
  }) =>
      OrgDrawer(
        indent ?? this.indent,
        header ?? this.header,
        body ?? this.body,
        footer ?? this.footer,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

/// A property in a drawer, like
/// ```
/// :CUSTOM_ID: foobar
/// ```
class OrgProperty extends OrgLeafNode with IndentedElement {
  OrgProperty(this.indent, this.key, this.value, this.trailing);

  @override
  final String indent;
  final String key;
  final String value;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      key.contains(pattern) || value.contains(pattern);

  @override
  String toString() => 'OrgProperty';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(key)
      ..write(value)
      ..write(trailing);
  }
}
