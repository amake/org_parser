part of '../model.dart';

/// A macro reference, like
/// ```
/// {{{my_macro}}}
/// ```
class OrgMacroReference extends OrgLeafNode with SingleContentElement {
  OrgMacroReference(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgMacroReference';
}
