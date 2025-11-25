part of '../model.dart';

class OrgPgpBlock extends OrgLeafNode with OrgElement {
  OrgPgpBlock(this.indent, this.header, this.body, this.footer, this.trailing);

  @override
  final String indent;
  final String header;
  final String body;
  final String footer;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern) ||
      trailing.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(header)
      ..write(body)
      ..write(footer)
      ..write(trailing);
  }

  /// Convert to RFC 4880 format for decryption
  ///
  /// See: https://www.rfc-editor.org/rfc/rfc4880#section-6.2
  //
  // Indent finagling consistent with `org-crypt--encrypted-text`
  String toRfc4880() =>
      toMarkup().trim().replaceAll(RegExp('^[ \t]*', multiLine: true), '');

  @override
  OrgPgpBlock copyWith({
    String? indent,
    String? header,
    String? body,
    String? footer,
    String? trailing,
  }) =>
      OrgPgpBlock(
        indent ?? this.indent,
        header ?? this.header,
        body ?? this.body,
        footer ?? this.footer,
        trailing ?? this.trailing,
      );
}
