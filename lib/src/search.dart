/// Identify queries that point to a section within the current document
/// (starting with '*')
bool isOrgLocalSectionSearch(String query) => query.startsWith('*');

/// Return the title of the section pointed to by the query. The query must be
/// one for which [isOrgLocalSectionSearch] returns true.
String parseOrgLocalSectionSearch(String query) {
  assert(isOrgLocalSectionSearch(query));
  return query.substring(1).replaceAll(RegExp('[ \t]*\r?\n[ \t]*'), ' ');
}

/// Identify queries that point to a custom ID (starting with '#').
///
/// Note that "custom IDs" are distinct from "IDs"; see [OrgFileLink.parse].
bool isOrgCustomIdSearch(String query) => query.startsWith('#');

/// Return the CUSTOM_ID of the section pointed to by the query. The query must
/// be one for which [isOrgCustomIdSearch] returns true.
String parseOrgCustomIdSearch(String query) {
  assert(isOrgCustomIdSearch(query));
  return query.substring(1);
}

/// Identify queries that point to IDs (starting with 'id:').
///
/// Note that "IDs" are distinct from "custom IDs"; see [isOrgCustomIdSearch].
///
/// An 'id:' "query" is actually an [OrgFileLink] without an
/// [OrgFileLink.extra]. This function exists because consumers will probably
/// need to handle resolving 'id:some-id' in the same way as '#some-custom-id'.
/// If the 'id:' link you are handling may have its own search option, then
/// resolve the section with the given id first, and then handle the search
/// option.
bool isOrgIdSearch(String query) =>
    query.startsWith('id:') && !query.contains('::');

/// Return the ID of the section pointed to by the query. The query must be one
/// for which [isOrgCustomIdSearch] returns true.
String parseOrgIdSearch(String query) {
  assert(isOrgIdSearch(query));
  return query.substring(3);
}

// See org-src-coderef-regexp
final _coderefSearchPattern =
    RegExp(r'^\((?<name>[-a-zA-Z0-9_][-a-zA-Z0-9_ ]*)\)$');

/// Identify queries that point to code references, like `(ref:my-function)`.
bool isCoderefSearch(String query) => _coderefSearchPattern.hasMatch(query);

/// Return the code reference name pointed to by the query. The query must be
/// one for which [isCoderefSearch] returns true.
String parseCoderefSearch(String query) {
  assert(isCoderefSearch(query));
  final match = _coderefSearchPattern.firstMatch(query);
  return match!.namedGroup('name')!;
}

/// Identify queries that are regular expressions, delimited by slashes.
bool isRegexpSearch(String query) =>
    query.length >= 2 && query.startsWith('/') && query.endsWith('/');

/// Return the regular expression pattern pointed to by the query. The query
/// must be one that [isRegexpSearch] returns true for.
String parseRegexpSearch(String query) {
  assert(isRegexpSearch(query));
  return query.substring(1, query.length - 1);
}

/// Identify queries that are line numbers (positive integers).
bool isLineNumberSearch(String query) {
  final num = int.tryParse(query);
  return num != null && num > 0;
}

/// Return the line number pointed to by the query. The query must be one that
/// [isLineNumberSearch] returns true for.
int parseLineNumberSearch(String query) {
  assert(isLineNumberSearch(query));
  return int.parse(query);
}
