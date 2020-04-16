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
}

class OrgDocument extends OrgTree {
  factory OrgDocument.parse(String text) =>
      OrgParser().parse(text).value as OrgDocument;

  OrgDocument(OrgContent content, Iterable<OrgSection> sections)
      : super(content, sections);

  @override
  int get level => 0;
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
}

class OrgPlainText extends OrgContentElement with SingleContentElement {
  OrgPlainText(this.content) : assert(content != null);
  @override
  final String content;
}

class OrgLink extends OrgContentElement {
  OrgLink(this.location, this.description) : assert(location != null);
  final String location;
  final String description;

  @override
  bool contains(Pattern pattern) =>
      location.contains(pattern) ||
      description != null && description.contains(pattern);
}

class OrgMarkup extends OrgContentElement with SingleContentElement {
  OrgMarkup(this.content, this.style)
      : assert(content != null),
        assert(style != null);
  @override
  final String content;
  final OrgStyle style;
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
          .map((row) => row.cellCount)
          .where((count) => count >= 0)
          .toSet()
          .length <
      2;

  int get columnCount => rows.map((row) => row.cellCount).reduce(max);

  @override
  bool contains(Pattern pattern) => rows.any((row) => row.contains(pattern));
}

abstract class OrgTableRow extends OrgContentElement {
  OrgTableRow(this.indent) : assert(indent != null);

  final String indent;

  int get cellCount;
}

class OrgTableDividerRow extends OrgTableRow {
  OrgTableDividerRow(String indent) : super(indent);

  @override
  int get cellCount => -1;

  @override
  bool contains(Pattern pattern) => false;
}

class OrgTableCellRow extends OrgTableRow {
  OrgTableCellRow(String indent, Iterable<OrgContent> cells)
      : cells = List.unmodifiable(cells ?? const <OrgContent>[]),
        super(indent);

  final List<OrgContent> cells;

  @override
  int get cellCount => cells.length;

  @override
  bool contains(Pattern pattern) => cells.any((cell) => cell.contains(pattern));
}

class OrgTimestamp extends OrgContentElement with SingleContentElement {
  OrgTimestamp(this.content) : assert(content != null);

  // TODO(aaron): Expose actual data
  @override
  final String content;
}

class OrgKeyword extends OrgContentElement with SingleContentElement {
  OrgKeyword(this.content) : assert(content != null);

  @override
  final String content;
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
  bool contains(Pattern pattern) {
    return indent.contains(pattern) || content.contains(pattern);
  }
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
}

class OrgListItem extends OrgContentElement {
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
}
