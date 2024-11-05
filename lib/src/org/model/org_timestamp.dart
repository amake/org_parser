part of '../model.dart';

/// A timestamp, like `[2020-05-05 Tue]`
class OrgTimestamp extends OrgLeafNode with SingleContentElement {
  OrgTimestamp(this.content);

  // TODO(aaron): Expose actual data
  @override
  final String content;

  @override
  String toString() => 'OrgTimestamp';
}
