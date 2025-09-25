/// Identify URLs that point to a section within the current document (starting
/// with '*')
bool isOrgLocalSectionUrl(String url) => url.startsWith('*');

/// Return the title of the section pointed to by the URL. The URL must be one
/// for which [isOrgLocalSectionUrl] returns true.
String parseOrgLocalSectionUrl(String url) {
  assert(isOrgLocalSectionUrl(url));
  return url.substring(1).replaceAll(RegExp('[ \t]*\r?\n[ \t]*'), ' ');
}

/// Identify URLs that point to a custom ID (starting with '#').
///
/// Note that "custom IDs" are distinct from "IDs"; see [isOrgIdUrl].
bool isOrgCustomIdUrl(String url) => url.startsWith('#');

/// Return the CUSTOM_ID of the section pointed to by the URL. The URL must be
/// one for which [isOrgCustomIdUrl] returns true.
String parseOrgCustomIdUrl(String url) {
  assert(isOrgCustomIdUrl(url));
  return url.substring(1);
}

/// Identify URLs that point to IDs (starting with 'id:').
///
/// Note that "IDs" are distinct from "custom IDs"; see [isOrgCustomIdUrl].
bool isOrgIdUrl(String url) => url.startsWith('id:');

/// Return the ID of the section pointed to by the URL. The URL must be one
/// for which [isOrgCustomIdUrl] returns true.
String parseOrgIdUrl(String url) {
  assert(isOrgIdUrl(url));
  return url.substring(3);
}

// See org-src-coderef-regexp
final _coderefUrlPattern =
    RegExp(r'^\((?<name>[-a-zA-Z0-9_][-a-zA-Z0-9_ ]*)\)$');

bool isCoderefUrl(String url) => _coderefUrlPattern.hasMatch(url);

String parseCoderefUrl(String url) {
  assert(isCoderefUrl(url));
  final match = _coderefUrlPattern.firstMatch(url);
  return match!.namedGroup('name')!;
}
