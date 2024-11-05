part of '../model.dart';

/// Plain text that has no markup
class OrgPlainText extends OrgLeafNode with SingleContentElement {
  OrgPlainText(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgPlainText';
}
