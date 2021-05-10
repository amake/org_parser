import 'dart:math';

import 'package:org_parser/org_parser.dart';

bool isOrgLocalSectionUrl(String url) => url.startsWith('*');

/// Return the title of the section pointed to by the URL. The URL must be one
/// for which [isOrgLocalSectionUrl] returns true.
String parseOrgLocalSectionUrl(String url) {
  assert(isOrgLocalSectionUrl(url));
  return url.substring(1).replaceAll(RegExp('[ \t]*\r?\n[ \t]*'), ' ');
}

bool isOrgCustomIdUrl(String url) => url.startsWith('#');

/// Return the CUSTOM_ID of the section pointed to by the URL. The URL must be
/// one for which [isOrgCustomIdUrl] returns true.
String parseOrgCustomIdUrl(String url) {
  assert(isOrgCustomIdUrl(url));
  return url.substring(1);
}

bool isOrgIdUrl(String url) => url.startsWith('id:');

/// Return the ID of the section pointed to by the URL. The URL must be one
/// for which [isOrgCustomIdUrl] returns true.
String parseOrgIdUrl(String url) {
  assert(isOrgIdUrl(url));
  return url.substring(3);
}

abstract class OrgNode {
  List<OrgNode> get children => const [];

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
}

abstract class OrgTree extends OrgNode {
  OrgTree(this.content, [Iterable<OrgSection>? sections])
      : sections = List.unmodifiable(sections ?? const <OrgSection>[]);
  final OrgContent? content;
  final List<OrgSection> sections;

  @override
  List<OrgNode> get children => [if (content != null) content!, ...sections];

  int get level;

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
}

class OrgDocument extends OrgTree {
  factory OrgDocument.parse(String text) =>
      org.parse(text).value as OrgDocument;

  OrgDocument(OrgContent? content, Iterable<OrgSection> sections)
      : super(content, sections);

  @override
  int get level => 0;

  @override
  String toString() => 'OrgDocument';
}

class OrgHeadline extends OrgNode {
  OrgHeadline(
    this.stars,
    this.keyword,
    this.priority,
    this.title,
    this.rawTitle, [
    Iterable<String>? tags,
  ]) : tags = List.unmodifiable(tags ?? const <String>[]);
  final String stars;
  final String? keyword;
  final String? priority;
  final OrgContent? title;

  // For resolving links
  final String? rawTitle;
  final List<String> tags;

  // -1 for trailing space
  int get level => stars.length - 1;

  @override
  List<OrgNode> get children => title == null ? const [] : [title!];

  @override
  bool contains(Pattern pattern) {
    final keyword = this.keyword;
    final title = this.title;
    return keyword != null && keyword.contains(pattern) ||
        title != null && title.contains(pattern) ||
        tags.any((tag) => tag.contains(pattern));
  }

  @override
  String toString() => 'OrgHeadline';
}

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
}

mixin IndentedElement {
  String get indent;

  String get trailing;
}

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
}

class OrgPlainText extends OrgNode with SingleContentElement {
  OrgPlainText(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgPlainText';
}

class OrgLink extends OrgNode {
  OrgLink(this.location, this.description);
  final String location;
  final String? description;

  @override
  bool contains(Pattern pattern) {
    final description = this.description;
    return location.contains(pattern) ||
        description != null && description.contains(pattern);
  }

  @override
  String toString() => 'OrgLink';
}

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
}

enum OrgStyle {
  bold,
  verbatim,
  italic,
  strikeThrough,
  underline,
  code,
}

class OrgMacroReference extends OrgNode with SingleContentElement {
  OrgMacroReference(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgMacroReference';
}

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
}

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
}

class OrgSrcBlock extends OrgBlock {
  OrgSrcBlock(
    this.language,
    String indent,
    String header,
    OrgNode body,
    String footer,
    String trailing,
  ) : super(indent, header, body, footer, trailing);

  final String? language;
}

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

  bool get rectangular =>
      rows
          .whereType<OrgTableCellRow>()
          .map((row) => row.cellCount)
          .toSet()
          .length <
      2;

  int get columnCount =>
      rows.whereType<OrgTableCellRow>().map((row) => row.cellCount).reduce(max);

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

class OrgTimestamp extends OrgNode with SingleContentElement {
  OrgTimestamp(this.content);

  // TODO(aaron): Expose actual data
  @override
  final String content;

  @override
  String toString() => 'OrgTimestamp';
}

class OrgKeyword extends OrgNode with SingleContentElement {
  OrgKeyword(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgKeyword';
}

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
}

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
}

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
}

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
}

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
}

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
}

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
}

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
}

class OrgLatexBlock extends OrgNode {
  OrgLatexBlock(
    this.environment,
    this.leading,
    this.begin,
    this.content,
    this.end,
    this.trailing,
  );

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
}

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
}

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
}

class OrgFileLink {
  factory OrgFileLink.parse(String text) =>
      orgFileLink.parse(text).value as OrgFileLink;

  OrgFileLink(this.scheme, this.body, this.extra);
  final String? scheme;
  final String body;
  final String? extra;

  bool get isRelative =>
      body.startsWith('.') || scheme != null && !body.startsWith('/');
}
