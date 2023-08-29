import 'dart:math';

import 'package:org_parser/org_parser.dart';

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

/// The base type of all Org AST objects
abstract class OrgNode {
  /// The children of this node. May be empty.
  List<OrgNode> get children => const [];

  /// Return true if this node or any of its children recursively match the
  /// supplied [pattern]
  bool contains(Pattern pattern);

  /// Walk AST with [visitor]. Specify a type [T] to only visit nodes of that
  /// type. The visitor function must return `true` to continue iterating, or
  /// `false` to stop.
  bool visit<T extends OrgNode>(bool Function(T) visitor) {
    final self = this;
    if (self is T) {
      if (!visitor.call(self)) {
        return false;
      }
    }
    for (final child in children) {
      if (!child.visit<T>(visitor)) {
        return false;
      }
    }
    return true;
  }

  String toMarkup() {
    final buf = StringBuffer();
    _toMarkupImpl(buf);
    return buf.toString();
  }

  void _toMarkupImpl(StringBuffer buf);
}

/// A node potentially containing [OrgSection]s
abstract class OrgTree extends OrgNode {
  OrgTree(this.content, [Iterable<OrgSection>? sections])
      : sections = List.unmodifiable(sections ?? const <OrgSection>[]);

  /// Leading content
  final OrgContent? content;

  /// Sections contained within this tree. These are also iterated by [children].
  final List<OrgSection> sections;

  /// Leading content, if present, followed by [sections]
  @override
  List<OrgNode> get children => [if (content != null) content!, ...sections];

  /// The "level" (depth) of this node in the tree; corresponds to the number of
  /// '*' characters in the section heading
  int get level;

  /// Walk only section nodes of the AST with [visitor]. More efficient than
  /// calling [visit]. The visitor function must return `true` to continue
  /// iterating, or `false` to stop.
  bool visitSections(bool Function(OrgSection) visitor) {
    final self = this;
    if (self is OrgSection && !visitor(self)) {
      return false;
    }
    for (final section in sections) {
      if (!section.visitSections(visitor)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool contains(Pattern pattern, {bool includeChildren = true}) {
    final content = this.content;
    if (content != null && content.contains(pattern)) {
      return true;
    }
    return includeChildren && children.any((child) => child.contains(pattern));
  }

  @override
  String toString() => runtimeType.toString();

  @override
  void _toMarkupImpl(StringBuffer buf) {
    for (final child in children) {
      child._toMarkupImpl(buf);
    }
  }
}

/// The top-level node representing a full Org document
class OrgDocument extends OrgTree {
  /// Parse an Org document in string form into an AST
  factory OrgDocument.parse(String text) =>
      org.parse(text).value as OrgDocument;

  OrgDocument(OrgContent? content, Iterable<OrgSection> sections)
      : super(content, sections);

  @override
  int get level => 0;

  @override
  String toString() => 'OrgDocument';
}

/// An Org headline, like
///
/// ```
/// **** TODO [#A] COMMENT Title :tag1:tag2:
/// ```
class OrgHeadline extends OrgNode {
  OrgHeadline(
    this.stars,
    this.keyword,
    this.priority,
    this.title,
    this.rawTitle,
    ({String leading, Iterable<String> values, String trailing})? tags,
    this.trailing,
  ) : tags = tags == null
            ? null
            : (
                leading: tags.leading,
                values: List.unmodifiable(tags.values),
                trailing: tags.trailing
              );

  /// Headline stars, like `*** `. Includes trailing spaces.
  final ({String value, String trailing}) stars;

  /// Headline keyword, like `TODO`
  final ({String value, String trailing})? keyword;

  /// Headline priority, like `A`
  final ({String leading, String value, String trailing})? priority;

  /// Headline title
  final OrgContent? title;

  /// A raw representation of the headline title. This is useful for resolving
  /// section links (see [isOrgLocalSectionUrl]), which will reference the raw
  /// title rather than the parsed title.
  final String? rawTitle;

  /// Headline tags, like `:tag1:tag2:`
  final ({String leading, List<String> values, String trailing})? tags;

  final String? trailing;

  int get level => stars.value.length;

  @override
  List<OrgNode> get children => title == null ? const [] : [title!];

  @override
  bool contains(Pattern pattern) {
    final keyword = this.keyword;
    final title = this.title;
    return keyword != null && keyword.value.contains(pattern) ||
        title != null && title.contains(pattern) ||
        tags?.values.any((tag) => tag.contains(pattern)) == true;
  }

  @override
  String toString() => 'OrgHeadline';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(stars.value)
      ..write(stars.trailing);
    if (keyword != null) {
      buf
        ..write(keyword!.value)
        ..write(keyword!.trailing);
    }
    if (priority != null) {
      buf
        ..write(priority!.leading)
        ..write(priority!.value)
        ..write(priority!.trailing);
    }
    title?._toMarkupImpl(buf);
    if (tags?.values.isNotEmpty == true) {
      buf.write(tags!.leading);
      for (final (i, tag) in tags!.values.indexed) {
        buf.write(tag);
        if (i < tags!.values.length - 1) {
          buf.write(':');
        }
      }
      buf.write(tags!.trailing);
    }
    buf.write(trailing ?? '');
  }
}

/// An Org section. May have nested sections, like
///
/// ```
/// * TODO [#A] COMMENT Title :tag1:tag2:
/// content
/// ** Sub section
/// more content
/// ```
class OrgSection extends OrgTree {
  OrgSection(
    this.headline,
    OrgContent? content, [
    Iterable<OrgSection>? sections,
  ]) : super(content, sections);
  final OrgHeadline headline;

  @override
  List<OrgNode> get children => [headline, ...super.children];

  @override
  int get level => headline.level;

  /// Get the ID properties from this section's PROPERTIES drawer, if any.
  List<String> get ids => _getProperties(':ID:');

  /// Get the CUSTOM_ID properties from this section's PROPERTIES drawer, if
  /// any.
  List<String> get customIds => _getProperties(':CUSTOM_ID:');

  List<String> _getProperties(String key) =>
      _propertiesDrawer
          ?.properties(key: key)
          .map<String>((prop) => prop.value.trim())
          .toList(growable: false) ??
      const [];

  /// Retrieve this section's PROPERTIES drawer, if it exists.
  OrgDrawer? get _propertiesDrawer {
    OrgDrawer? result;
    // Visit [content], not [this], because we don't want to find a drawer in a
    // child section
    content?.visit<OrgDrawer>((drawer) {
      if (drawer.header.trim().toUpperCase() == ':PROPERTIES:') {
        result = drawer;
        // Only first drawer is recognized
        return false;
      }
      return true;
    });
    return result;
  }

  /// A section may be empty if it has no content or sub-sections
  bool get isEmpty => content == null && sections.isEmpty;

  OrgSection copyWith({
    OrgHeadline? headline,
    OrgContent? content,
    Iterable<OrgSection>? sections,
  }) =>
      OrgSection(
        headline ?? this.headline,
        content ?? this.content,
        sections ?? this.sections,
      );

  @override
  bool contains(Pattern pattern, {bool includeChildren = true}) =>
      headline.contains(pattern) ||
      super.contains(pattern, includeChildren: includeChildren);

  @override
  String toString() => 'OrgSection';
}

mixin SingleContentElement {
  String get content;

  bool contains(Pattern pattern) => content.contains(pattern);

  void _toMarkupImpl(StringBuffer buf) {
    buf.write(content);
  }
}

mixin IndentedElement {
  /// Indenting whitespace
  String get indent;

  /// Trailing whitespace
  String get trailing;
}

/// A generic node that contains children
class OrgContent extends OrgNode {
  OrgContent(Iterable<OrgNode> children)
      : children = List.unmodifiable(children);

  @override
  final List<OrgNode> children;

  @override
  bool contains(Pattern pattern) =>
      children.any((child) => child.contains(pattern));

  @override
  String toString() => 'OrgContent';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    for (final child in children) {
      child._toMarkupImpl(buf);
    }
  }
}

/// Plain text that has no markup
class OrgPlainText extends OrgNode with SingleContentElement {
  OrgPlainText(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgPlainText';
}

/// A link, like
/// ```
/// [[https://example.com][An example]]
/// ```
/// or
/// ```
/// [[https://example.com]]
/// ```
/// or
/// ```
/// https://example.com
/// ```
class OrgLink extends OrgNode {
  OrgLink(this.location, this.description);

  /// Where the link points
  final String location;

  /// The user-visible text
  final String? description;

  @override
  bool contains(Pattern pattern) {
    final description = this.description;
    return location.contains(pattern) ||
        description != null && description.contains(pattern);
  }

  @override
  String toString() => 'OrgLink';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    // TODO(aaron): Properly restore naked URL
    buf
      ..write('[[')
      ..write(location);
    if (description != null) {
      buf
        ..write('][')
        ..write(description);
    }
    buf.write(']]');
  }
}

/// Emphasis markup, like
/// ```
/// *bold*
/// /italic/
/// +strikethrough+
/// ~code~
/// =verbatim=
/// ```
///
/// See [OrgStyle] for supported emphasis types
class OrgMarkup extends OrgNode {
  // TODO(aaron): Get rid of this hack
  OrgMarkup.just(String content, OrgStyle style) : this('', content, '', style);

  OrgMarkup(
    this.leadingDecoration,
    this.content,
    this.trailingDecoration,
    this.style,
  );

  final String leadingDecoration;
  final String content;
  final String trailingDecoration;
  final OrgStyle style;

  @override
  String toString() => 'OrgMarkup';

  @override
  bool contains(Pattern pattern) =>
      leadingDecoration.contains(pattern) ||
      content.contains(pattern) ||
      trailingDecoration.contains(pattern);

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(leadingDecoration)
      ..write(content)
      ..write(trailingDecoration);
  }
}

/// Supported styles for [OrgMarkup] nodes
enum OrgStyle {
  bold,
  verbatim,
  italic,
  strikeThrough,
  underline,
  code,
}

/// A macro reference, like
/// ```
/// {{{my_macro}}}
/// ```
class OrgMacroReference extends OrgNode with SingleContentElement {
  OrgMacroReference(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgMacroReference';
}

/// A "meta" line, like
/// ```
/// #+KEYWORD: some-named-thing
/// ```
///
/// TODO(aaron): Should this be renamed to `OrgKeyword`?
class OrgMeta extends OrgNode with IndentedElement {
  OrgMeta(this.indent, this.keyword, this.trailing);

  @override
  final String indent;
  final String keyword;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) {
    return indent.contains(pattern) ||
        keyword.contains(pattern) ||
        trailing.contains(pattern);
  }

  @override
  String toString() => 'OrgMeta';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(indent)
      ..write(keyword)
      ..write(trailing);
  }
}

/// A block, like
/// ```
/// #+begin_quote
/// foo
/// #+end_quote
/// ```
///
/// See also [OrgSrcBlock]
class OrgBlock extends OrgNode with IndentedElement {
  OrgBlock(this.indent, this.header, this.body, this.footer, this.trailing);

  @override
  final String indent;
  final String header;
  final OrgNode body;
  final String footer;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [body];

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);

  @override
  String toString() => 'OrgBlock';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(indent)
      ..write(header);
    body._toMarkupImpl(buf);
    buf
      ..write(footer)
      ..write(trailing);
  }
}

/// A source block, like
/// ```
/// #+begin_src sh
///   echo "hello world"
/// #+end_src
/// ```
class OrgSrcBlock extends OrgBlock {
  OrgSrcBlock(
    this.language,
    String indent,
    String header,
    OrgNode body,
    String footer,
    String trailing,
  ) : super(indent, header, body, footer, trailing);

  /// The language of the block, like `sh`
  final String? language;
}

/// A table, like
/// ```
/// | Foo         |    Bar |  Baz |
/// |-------------+--------+------|
/// | Lorem ipsum | 30.000 |    1 |
/// | 123         |        |      |
/// ```
class OrgTable extends OrgNode with IndentedElement {
  OrgTable(Iterable<OrgTableRow> rows, this.trailing)
      : rows = List.unmodifiable(rows);

  final List<OrgTableRow> rows;

  @override
  List<OrgNode> get children => rows;

  @override
  String get indent => rows.isEmpty ? '' : rows.first.indent;
  @override
  final String trailing;

  /// The table is rectangular if all rows contain the same number of cells
  bool get rectangular =>
      rows
          .whereType<OrgTableCellRow>()
          .map((row) => row.cellCount)
          .toSet()
          .length <
      2;

  /// The maximum number of columns in any row of the table
  int get columnCount =>
      rows.whereType<OrgTableCellRow>().map((row) => row.cellCount).reduce(max);

  /// Determine whether the column number [colIdx] should be treated as a
  /// numeric column. A certain percentage of non-numeric cells are tolerated.
  bool columnIsNumeric(int colIdx) {
    final cells = rows
        .whereType<OrgTableCellRow>()
        .map((row) => row.cells[colIdx])
        .toList(growable: false);
    final totalCount = cells.length;
    final emptyCount = cells.where(_tableCellIsEmpty).length;
    final nonEmptyCount = totalCount - emptyCount;
    final numberCount = cells.where(_tableCellIsNumeric).length;
    return numberCount / nonEmptyCount >= _orgTableNumberFraction;
  }

  @override
  bool contains(Pattern pattern) => rows.any((row) => row.contains(pattern));

  @override
  String toString() => 'OrgTable';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    for (final row in rows) {
      buf.write(indent);
      row._toMarkupImpl(buf);
      buf.write('\n');
    }
  }
}

abstract class OrgTableRow extends OrgNode {
  OrgTableRow(this.indent);

  final String indent;

  @override
  String toString() => runtimeType.toString();
}

class OrgTableDividerRow extends OrgTableRow {
  OrgTableDividerRow(String indent) : super(indent);

  @override
  bool contains(Pattern pattern) => false;

  @override
  String toString() => 'OrgTableDividerRow';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    // TODO(aaron): Restore this
  }
}

class OrgTableCellRow extends OrgTableRow {
  OrgTableCellRow(String indent, Iterable<OrgContent> cells)
      : cells = List.unmodifiable(cells),
        super(indent);

  final List<OrgContent> cells;

  @override
  List<OrgNode> get children => cells;

  int get cellCount => cells.length;

  @override
  bool contains(Pattern pattern) => cells.any((cell) => cell.contains(pattern));

  @override
  String toString() => 'OrgTableCellRow';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    // TODO(aaron): Restore actual leading, trailing spaces for each cell
    if (cells.isEmpty) {
      buf.write('||');
      return;
    }
    buf.write('| ');
    for (final (i, cell) in cells.indexed) {
      cell._toMarkupImpl(buf);
      buf.write(' |');
      if (i < cells.length - 1) {
        buf.write(' ');
      }
    }
  }
}

bool _tableCellIsNumeric(OrgContent cell) {
  if (cell.children.length == 1) {
    final content = cell.children.first;
    if (content is OrgPlainText) {
      return _orgTableNumberRegexp.hasMatch(content.content);
    }
  }
  return false;
}

bool _tableCellIsEmpty(OrgContent cell) => cell.children.isEmpty;

// Default number-detecting regexp from org-mode 20200504, converted with:
//   (kill-new (rxt-elisp-to-pcre org-table-number-regexp))
final _orgTableNumberRegexp = RegExp(
    r'^([><]?[.\^+\-0-9]*[0-9][:%)(xDdEe.\^+\-0-9]*|[><]?[+\-]?0[Xx][.[:xdigit:]]+|[><]?[+\-]?[0-9]+#[.A-Za-z0-9]+|nan|[u+\-]?inf)$');

// Default fraction of non-empty cells in a column to make the column
// right-aligned. From org-mode 20200504.
const _orgTableNumberFraction = 0.5;

/// A timestamp, like `[2020-05-05 Tue]`
class OrgTimestamp extends OrgNode with SingleContentElement {
  OrgTimestamp(this.content);

  // TODO(aaron): Expose actual data
  @override
  final String content;

  @override
  String toString() => 'OrgTimestamp';
}

/// A planning keyword, like `SCHEDULED:` or `DEADLINE:`
///
/// TODO(aaron): Rename this to "OrgPlanningKeyword"?
class OrgKeyword extends OrgNode with SingleContentElement {
  OrgKeyword(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgKeyword';
}

/// A planning line, like
/// ```
/// SCHEDULED: <2021-12-09 Thu>
/// ```
/// or
/// ```
/// CLOSED: [2021-12-09 Thu 12:02]
/// ```
class OrgPlanningLine extends OrgNode with IndentedElement {
  OrgPlanningLine(this.indent, this.keyword, this.body, this.trailing);

  @override
  final String indent;
  final OrgKeyword keyword;
  final OrgContent body;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [keyword, body];

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      keyword.contains(pattern) ||
      body.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgPlanningLine';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf.write(indent);
    keyword._toMarkupImpl(buf);
    body._toMarkupImpl(buf);
    buf.write(trailing);
  }
}

/// A fixed-width area, like
/// ```
/// : result of source block, or whatever
/// ```
class OrgFixedWidthArea extends OrgNode with IndentedElement {
  OrgFixedWidthArea(this.indent, this.content, this.trailing);

  @override
  final String indent;
  final String content;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      content.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgFixedWidthArea';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(indent)
      ..write(content)
      ..write(trailing);
  }
}

/// A list, like
/// ```
/// - foo
/// - bar
///   - baz
/// ```
class OrgList extends OrgNode with IndentedElement {
  OrgList(Iterable<OrgListItem> items, this.trailing)
      : items = List.unmodifiable(items);
  final List<OrgListItem> items;

  @override
  String get indent => items.isEmpty ? '' : items.first.indent;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) => items.any((item) => item.contains(pattern));

  @override
  String toString() => 'OrgList';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    for (final item in items) {
      item._toMarkupImpl(buf);
    }
    buf.write(trailing);
  }
}

abstract class OrgListItem extends OrgNode {
  OrgListItem(this.indent, this.bullet, this.checkbox, this.body);

  final String indent;
  final String bullet;
  final String? checkbox;
  final OrgContent? body;

  @override
  List<OrgNode> get children => body == null ? const [] : [body!];

  @override
  bool contains(Pattern pattern) {
    final checkbox = this.checkbox;
    final body = this.body;
    return indent.contains(pattern) ||
        bullet.contains(pattern) ||
        checkbox != null && checkbox.contains(pattern) ||
        body != null && body.contains(pattern);
  }

  @override
  String toString() => runtimeType.toString();
}

/// An unordered list item, like
/// ```
/// - foo
/// ```
class OrgListUnorderedItem extends OrgListItem {
  OrgListUnorderedItem(
    String indent,
    String bullet,
    String? checkbox,
    this.tag,
    this.tagDelimiter,
    OrgContent? body,
  )   : assert(tag == null && tagDelimiter == null ||
            tag != null && tagDelimiter != null),
        super(indent, bullet, checkbox, body);

  final OrgContent? tag;
  final String? tagDelimiter;

  @override
  List<OrgNode> get children => [if (tag != null) tag!, ...super.children];

  @override
  bool contains(Pattern pattern) {
    final tag = this.tag;
    final tagDelimiter = this.tagDelimiter;
    return tag != null && tag.contains(pattern) ||
        tagDelimiter != null && tagDelimiter.contains(pattern) ||
        super.contains(pattern);
  }

  @override
  String toString() => 'OrgListUnorderedItem';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(indent)
      ..write(bullet)
      ..write(checkbox)
      ..write(tag)
      ..write(tagDelimiter);
    body?._toMarkupImpl(buf);
  }
}

/// An ordered list item, like
/// ```
/// 1. foo
/// ```
class OrgListOrderedItem extends OrgListItem {
  OrgListOrderedItem(
    String indent,
    String bullet,
    this.counterSet,
    String? checkbox,
    OrgContent? body,
  ) : super(indent, bullet, checkbox, body);

  final String? counterSet;

  @override
  bool contains(Pattern pattern) {
    final counterSet = this.counterSet;
    return counterSet != null && counterSet.contains(pattern) ||
        super.contains(pattern);
  }

  @override
  String toString() => 'OrgListOrderedItem';
  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(indent)
      ..write(bullet)
      ..write(counterSet)
      ..write(checkbox);
    body?._toMarkupImpl(buf);
  }
}

class OrgParagraph extends OrgNode {
  OrgParagraph(this.indent, this.body);

  final String indent;
  final OrgContent body;

  @override
  List<OrgNode> get children => [body];

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) || body.contains(pattern);

  @override
  String toString() => 'OrgParagraph';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf.write(indent);
    body._toMarkupImpl(buf);
  }
}

/// A drawer, like
/// ```
/// :PROPERTIES:
/// :CUSTOM_ID: foobar
/// :END:
/// ```
class OrgDrawer extends OrgNode with IndentedElement {
  OrgDrawer(this.indent, this.header, this.body, this.footer, this.trailing);

  @override
  final String indent;
  final String header;
  final OrgNode body;
  final String footer;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [body];

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

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);

  @override
  String toString() => 'OrgDrawer';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(indent)
      ..write(header);
    body._toMarkupImpl(buf);
    buf
      ..write(footer)
      ..write(trailing);
  }
}

/// A property in a drawer, like
/// ```
/// :CUSTOM_ID: foobar
/// ```
class OrgProperty extends OrgNode with IndentedElement {
  OrgProperty(this.indent, this.key, this.value, this.trailing);

  @override
  final String indent;
  final String key;
  final String value;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      key.contains(pattern) || value.contains(pattern);

  @override
  String toString() => 'OrgProperty';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(indent)
      ..write(key)
      ..write(value)
      ..write(trailing);
  }
}

/// A footnote, like
/// ```
/// [fn:1] this is a footnote
/// ```
class OrgFootnote extends OrgNode {
  OrgFootnote(this.marker, this.content);

  final OrgFootnoteReference marker;
  final OrgContent content;

  @override
  List<OrgNode> get children => [marker, content];

  @override
  bool contains(Pattern pattern) =>
      marker.contains(pattern) || content.contains(pattern);

  @override
  String toString() => 'OrgFootnote';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    marker._toMarkupImpl(buf);
    content._toMarkupImpl(buf);
  }
}

/// A footnote reference, like `[fn:1]`
class OrgFootnoteReference extends OrgNode {
  OrgFootnoteReference.named(String leading, String name, String trailing)
      : this(leading, name, null, null, trailing);

  OrgFootnoteReference(
    this.leading,
    this.name,
    this.definitionDelimiter,
    this.definition,
    this.trailing,
  );

  final String leading;
  final String? name;
  final String? definitionDelimiter;
  final OrgContent? definition;
  final String trailing;

  @override
  List<OrgNode> get children => [if (definition != null) definition!];

  @override
  bool contains(Pattern pattern) {
    final name = this.name;
    final definitionDelimiter = this.definitionDelimiter;
    final definition = this.definition;
    return leading.contains(pattern) ||
        name != null && name.contains(pattern) ||
        definitionDelimiter != null && definitionDelimiter.contains(pattern) ||
        definition != null && definition.contains(pattern) ||
        trailing.contains(pattern);
  }

  @override
  String toString() => 'OrgFootnoteReference';

  @override
  void _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(leading)
      ..write(name ?? '')
      ..write(definitionDelimiter ?? '');
    definition?._toMarkupImpl(buf);
    buf.write(trailing);
  }
}

/// A LaTeX block, like
/// ```
/// \begin{equation}
/// \nabla \cdot \mathbf{B} = 0
/// \end{equation}
/// ```
class OrgLatexBlock extends OrgNode {
  OrgLatexBlock(
    this.environment,
    this.leading,
    this.begin,
    this.content,
    this.end,
    this.trailing,
  );

  /// The LaTeX environment, like `equation`
  final String environment;
  final String leading;
  final String begin;
  final String content;
  final String end;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      begin.contains(pattern) ||
      content.contains(pattern) ||
      end.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgLatexBlock';

  @override
  _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(leading)
      ..write(begin)
      ..write(content)
      ..write(end)
      ..write(trailing);
  }
}

/// An inline LaTeX snippet, like `$E=mc^2$`
class OrgLatexInline extends OrgNode {
  OrgLatexInline(
    this.leadingDecoration,
    this.content,
    this.trailingDecoration,
  );

  final String leadingDecoration;
  final String content;
  final String trailingDecoration;

  @override
  String toString() => 'OrgLatexInline';

  @override
  bool contains(Pattern pattern) =>
      leadingDecoration.contains(pattern) ||
      content.contains(pattern) ||
      trailingDecoration.contains(pattern);

  @override
  _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(leadingDecoration)
      ..write(content)
      ..write(trailingDecoration);
  }
}

/// An entity, like `\Omega`
class OrgEntity extends OrgNode {
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
  _toMarkupImpl(StringBuffer buf) {
    buf
      ..write(leading)
      ..write(name)
      ..write(trailing);
  }
}

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
}
