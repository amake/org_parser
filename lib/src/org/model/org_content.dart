part of '../model.dart';

/// A generic node that contains children
class OrgContent extends OrgParentNode {
  OrgContent(Iterable<OrgNode> children, [super.id])
      : children = children.length == 1 && children.firstOrNull is OrgContent
            ? (children.first as OrgContent).children
            : List.unmodifiable(children);

  @override
  final List<OrgNode> children;

  @override
  OrgContent fromChildren(List<OrgNode> children) =>
      copyWith(children: children);

  @override
  bool contains(Pattern pattern) =>
      children.any((child) => child.contains(pattern));

  @override
  String toString() => 'OrgContent';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    for (final child in children) {
      buf.visit(child);
    }
  }

  OrgContent copyWith({List<OrgNode>? children, String? id}) =>
      OrgContent(children ?? this.children, id ?? this.id);
}
