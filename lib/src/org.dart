import 'dart:math';

import 'package:org_parser/org_parser.dart';

bool isOrgLocalSectionUrl(String url) => url.startsWith('*');

/// Return the title of the section pointed to by the URL. The URL must be one
/// for which [isOrgLocalSectionUrl] returns true.
String parseOrgLocalSectionUrl(String url) {
  assert(isOrgLocalSectionUrl(url));
  return url.substring(1).replaceAll(RegExp('[ \t]*\r?\n[ \t]*'), ' ');
}

abstract class OrgTree {
  OrgTree(this.content, [Iterable<OrgSection> children])
      : children = List.unmodifiable(children ?? const <OrgSection>[]);
  final OrgContent content;
  final List<OrgSection> children;

  int get level;

  bool contains(Pattern pattern, {bool includeChildren = true}) {
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
      OrgParser().parse(text).value as OrgDocument;

  OrgDocument(OrgContent content, Iterable<OrgSection> sections)
      : super(content, sections);

  @override
  int get level => 0;

  @override
  String toString() => 'OrgDocument';
}

class OrgHeadline {
  OrgHeadline(
    this.stars,
    this.keyword,
    this.priority,
    this.title,
    this.rawTitle, [
    Iterable<String> tags = const [],
  ]) : tags = List.unmodifiable(tags ?? const <String>[]);
  final String stars;
  final String keyword;
  final String priority;
  final OrgContent title;

  // For resolving links
  final String rawTitle;
  final List<String> tags;

  // -1 for trailing space
  int get level => stars.length - 1;

  bool contains(Pattern pattern) =>
      keyword != null && keyword.contains(pattern) ||
      title != null && title.contains(pattern) ||
      tags.any((tag) => tag.contains(pattern));

  @override
  String toString() => 'OrgHeadline';
}

class OrgSection extends OrgTree {
  OrgSection(
    this.headline,
    OrgContent content, [
    Iterable<OrgSection> children,
  ]) : super(content, children);
  final OrgHeadline headline;

  @override
  int get level => headline.level;

  bool get isEmpty => content == null && children.isEmpty;

  OrgSection copyWith({
    OrgHeadline headline,
    OrgContent content,
    Iterable<OrgSection> children,
  }) =>
      OrgSection(
        headline ?? this.headline,
        content ?? this.content,
        children ?? this.children,
      );

  @override
  bool contains(Pattern pattern, {bool includeChildren = true}) =>
      headline.contains(pattern) ||
      super.contains(pattern, includeChildren: includeChildren);

  @override
  String toString() => 'OrgSection';
}

// ignore: one_member_abstracts
abstract class OrgContentElement {
  bool contains(Pattern pattern);
}

mixin SingleContentElement {
  String get content;

  bool contains(Pattern pattern) => content.contains(pattern);
}

mixin IndentedElement {
  String get indent;

  String get trailing;
}

class OrgContent extends OrgContentElement {
  OrgContent(Iterable<OrgContentElement> children)
      : children = List.unmodifiable(children),
        assert(children != null);

  final List<OrgContentElement> children;

  @override
  bool contains(Pattern pattern) =>
      children.any((child) => child.contains(pattern));

  @override
  String toString() => 'OrgContent';
}

class OrgPlainText extends OrgContentElement with SingleContentElement {
  OrgPlainText(this.content) : assert(content != null);

  @override
  final String content;

  @override
  String toString() => 'OrgPlainText';
}

class OrgLink extends OrgContentElement {
  OrgLink(this.location, this.description) : assert(location != null);
  final String location;
  final String description;

  @override
  bool contains(Pattern pattern) =>
      location.contains(pattern) ||
      description != null && description.contains(pattern);

  @override
  String toString() => 'OrgLink';
}

class OrgMarkup extends OrgContentElement {
  // TODO(aaron): Get rid of this hack
  OrgMarkup.just(String content, OrgStyle style) : this('', content, '', style);

  OrgMarkup(
    this.leadingDecoration,
    this.content,
    this.trailingDecoration,
    this.style,
  )   : assert(leadingDecoration != null),
        assert(content != null),
        assert(trailingDecoration != null),
        assert(style != null);

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

class OrgMacroReference extends OrgContentElement with SingleContentElement {
  OrgMacroReference(this.content) : assert(content != null);

  @override
  final String content;

  @override
  String toString() => 'OrgMacroReference';
}

class OrgMeta extends OrgContentElement {
  OrgMeta(this.indent, this.keyword, this.trailing)
      : assert(indent != null),
        assert(keyword != null),
        assert(trailing != null);

  final String indent;
  final String keyword;
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

class OrgBlock extends OrgContentElement with IndentedElement {
  OrgBlock(this.indent, this.header, this.body, this.footer, this.trailing)
      : assert(indent != null),
        assert(header != null),
        assert(body != null),
        assert(footer != null),
        assert(trailing != null);
  @override
  final String indent;
  final String header;
  final OrgContentElement body;
  final String footer;
  @override
  final String trailing;

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
    OrgContentElement body,
    String footer,
    String trailing,
  ) : super(indent, header, body, footer, trailing);

  final String language;
}

class OrgTable extends OrgContentElement with IndentedElement {
  OrgTable(Iterable<OrgTableRow> rows, this.trailing)
      : assert(trailing != null),
        rows = List.unmodifiable(rows ?? const <OrgTableRow>[]);

  final List<OrgTableRow> rows;

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

abstract class OrgTableRow extends OrgContentElement {
  OrgTableRow(this.indent) : assert(indent != null);

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
      : cells = List.unmodifiable(cells ?? const <OrgContent>[]),
        super(indent);

  final List<OrgContent> cells;

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

class OrgTimestamp extends OrgContentElement with SingleContentElement {
  OrgTimestamp(this.content) : assert(content != null);

  // TODO(aaron): Expose actual data
  @override
  final String content;

  @override
  String toString() => 'OrgTimestamp';
}

class OrgKeyword extends OrgContentElement with SingleContentElement {
  OrgKeyword(this.content) : assert(content != null);

  @override
  final String content;

  @override
  String toString() => 'OrgKeyword';
}

class OrgFixedWidthArea extends OrgContentElement with IndentedElement {
  OrgFixedWidthArea(this.indent, this.content, this.trailing)
      : assert(indent != null),
        assert(content != null),
        assert(trailing != null);
  @override
  final String indent;
  final String content;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) || content.contains(pattern);

  @override
  String toString() => 'OrgFixedWidthArea';
}

class OrgList extends OrgContentElement with IndentedElement {
  OrgList(Iterable<OrgListItem> items, this.trailing)
      : assert(trailing != null),
        items = List.unmodifiable(items ?? const <OrgListItem>[]);
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

abstract class OrgListItem extends OrgContentElement {
  OrgListItem(this.indent, this.bullet, this.checkbox, this.body)
      : assert(indent != null),
        assert(bullet != null);

  final String indent;
  final String bullet;
  final String checkbox;
  final OrgContent body;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      bullet.contains(pattern) ||
      checkbox != null && checkbox.contains(pattern) ||
      body != null && body.contains(pattern);

  @override
  String toString() => runtimeType.toString();
}

class OrgListUnorderedItem extends OrgListItem {
  OrgListUnorderedItem(
    String indent,
    String bullet,
    String checkbox,
    this.tag,
    this.tagDelimiter,
    OrgContent body,
  )   : assert(tag == null && tagDelimiter == null ||
            tag != null && tagDelimiter != null),
        super(indent, bullet, checkbox, body);

  final OrgContent tag;
  final String tagDelimiter;

  @override
  bool contains(Pattern pattern) =>
      tag != null && tag.contains(pattern) ||
      tagDelimiter != null && tagDelimiter.contains(pattern) ||
      super.contains(pattern);

  @override
  String toString() => 'OrgListUnorderedItem';
}

class OrgListOrderedItem extends OrgListItem {
  OrgListOrderedItem(
    String indent,
    String bullet,
    this.counterSet,
    String checkbox,
    OrgContent body,
  ) : super(indent, bullet, checkbox, body);

  final String counterSet;

  @override
  bool contains(Pattern pattern) =>
      counterSet != null && counterSet.contains(pattern) ||
      super.contains(pattern);

  @override
  String toString() => 'OrgListOrderedItem';
}

class OrgParagraph extends OrgContentElement {
  OrgParagraph(this.indent, this.body)
      : assert(indent != null),
        assert(body != null);
  final String indent;
  final OrgContent body;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) || body.contains(pattern);

  @override
  String toString() => 'OrgParagraph';
}

class OrgDrawer extends OrgContentElement with IndentedElement {
  OrgDrawer(this.indent, this.header, this.body, this.footer, this.trailing)
      : assert(indent != null),
        assert(header != null),
        assert(body != null),
        assert(footer != null),
        assert(trailing != null);
  @override
  final String indent;
  final String header;
  final OrgContentElement body;
  final String footer;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);

  @override
  String toString() => 'OrgDrawer';
}

class OrgProperty extends OrgContentElement {
  OrgProperty(this.indent, this.key, this.value, this.trailing)
      : assert(indent != null),
        assert(key != null),
        assert(value != null),
        assert(trailing != null);
  final String indent;
  final String key;
  final String value;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      key.contains(pattern) || value.contains(pattern);

  @override
  String toString() => 'OrgProperty';
}

class OrgFootnote extends OrgContentElement {
  OrgFootnote(this.marker, this.content)
      : assert(marker != null),
        assert(content != null);
  final OrgFootnoteReference marker;
  final OrgContent content;

  @override
  bool contains(Pattern pattern) =>
      marker.contains(pattern) || content.contains(pattern);

  @override
  String toString() => 'OrgFootnote';
}

class OrgFootnoteReference extends OrgContentElement {
  OrgFootnoteReference.named(String leading, String name, String trailing)
      : this(leading, name, null, null, trailing);

  OrgFootnoteReference(
    this.leading,
    this.name,
    this.definitionDelimiter,
    this.definition,
    this.trailing,
  )   : assert(leading != null),
        assert(trailing != null);
  final String leading;
  final String name;
  final String definitionDelimiter;
  final OrgContent definition;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      name != null && name.contains(pattern) ||
      definitionDelimiter != null && definitionDelimiter.contains(pattern) ||
      definition != null && definition.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgFootnoteReference';
}

class OrgLatexBlock extends OrgContentElement {
  OrgLatexBlock(
    this.environment,
    this.leading,
    this.begin,
    this.content,
    this.end,
    this.trailing,
  )   : assert(environment != null),
        assert(leading != null),
        assert(begin != null),
        assert(content != null),
        assert(end != null),
        assert(trailing != null);

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

class OrgLatexInline extends OrgContentElement {
  OrgLatexInline(
    this.leadingDecoration,
    this.content,
    this.trailingDecoration,
  )   : assert(leadingDecoration != null),
        assert(content != null),
        assert(trailingDecoration != null);

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

class OrgEntity extends OrgContentElement {
  OrgEntity(this.leading, this.name, this.trailing)
      : assert(leading != null),
        assert(name != null),
        assert(trailing != null);
  final String leading;
  final String name;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      name.contains(pattern) ||
      trailing.contains(pattern);
}
