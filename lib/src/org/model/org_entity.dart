part of '../model.dart';

/// An entity, like `\Omega`
class OrgEntity extends OrgLeafNode {
  OrgEntity(this.leading, this.name, this.trailing);

  final String leading;
  final String name;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      name.contains(pattern) ||
      trailing.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(name)
      ..write(trailing);
  }
}
