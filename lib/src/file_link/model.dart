import 'package:org_parser/src/file_link/parser.dart';

/// A link to a file, like
/// ```
/// file:/foo/bar.org::#custom-id
/// ```
class OrgFileLink {
  factory OrgFileLink.parse(String text) =>
      orgFileLink.parse(text).value as OrgFileLink;

  OrgFileLink(this.scheme, this.body, this.extra);
  final String? scheme;
  final String body;
  final String? extra;

  /// Whether the file linked to is indicated by a relative path (as opposed to
  /// an absolute path). Also true for local links.
  bool get isRelative =>
      isLocal ||
      body.startsWith('.') ||
      scheme != null && !body.startsWith('/');

  /// Whether this link points to a section within the current document.
  bool get isLocal => body.isEmpty && extra != null;

  OrgFileLink copyWith({String? scheme, String? body, String? extra}) =>
      OrgFileLink(
        scheme ?? this.scheme,
        body ?? this.body,
        extra ?? this.extra,
      );
}
