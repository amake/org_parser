part of '../model.dart';

/// A drawer, like
/// ```
/// :PROPERTIES:
/// :CUSTOM_ID: foobar
/// :END:
/// ```
class OrgDrawer extends OrgParentNode with OrgElement {
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
  final OrgContent body;
  final String footer;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [body];

  @override
  OrgDrawer fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single as OrgContent);

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

  // TODO(aaron): We could also support appending, etc.
  OrgDrawer setProperty(OrgProperty property) {
    var didReplace = false;
    var newBody = body.edit().visit((location) {
      final node = location.node;
      if (node is! OrgProperty) return (true, null);
      if (node.key.toUpperCase() != property.key.toUpperCase()) {
        return (true, null);
      }
      location = location.replace(property);
      didReplace = true;
      return (true, location);
    }).commit<OrgContent>();

    if (!didReplace) {
      newBody = newBody.copyWith(
        children: [...newBody.children, property],
      );
    }

    return copyWith(body: newBody);
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
    OrgContent? body,
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
class OrgProperty extends OrgParentNode with OrgElement {
  OrgProperty(this.indent, this.key, this.value, this.trailing, [super.id]);

  @override
  final String indent;
  final String key;
  final OrgContent value;
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
      ..visit(value)
      ..write(trailing);
  }

  @override
  List<OrgNode> get children => [value];

  @override
  OrgParentNode fromChildren(List<OrgNode> children) =>
      copyWith(value: children.single as OrgContent);

  OrgProperty copyWith({
    String? indent,
    String? key,
    OrgContent? value,
    String? trailing,
    String? id,
  }) =>
      OrgProperty(
        indent ?? this.indent,
        key ?? this.key,
        value ?? this.value,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}
