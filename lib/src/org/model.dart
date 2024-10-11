import 'dart:math';

import 'package:functional_zipper/functional_zipper.dart';
import 'package:org_parser/org_parser.dart';

typedef OrgPath = List<OrgNode>;

/// A class for serializing Org AST objects to Org Mode markup. Subclass and
/// supply to [OrgNode.toMarkup] to customize serialization.
class OrgSerializer {
  final _buf = StringBuffer();

  void visit(OrgNode node) => node._toMarkupImpl(this);

  void write(String str) => _buf.write(str);

  @override
  String toString() => _buf.toString();
}

/// The base type of all Org AST objects
abstract class OrgNode {
  /// The children of this node. May be empty (no children) or null (an object
  /// that can't have children).
  List<OrgNode>? get children;

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
    if (children != null) {
      for (final child in children!) {
        if (!child.visit<T>(visitor)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Find the first node in the AST that satisfies [predicate]. Specify a type
  /// [T] to only visit nodes of that type. Returns a tuple of the node and its
  /// path from the root of the tree, or null if no node is found.
  ({T node, OrgPath path})? find<T extends OrgNode>(
    bool Function(T) predicate, [
    OrgPath path = const [],
  ]) {
    final self = this;
    if (path.isEmpty) {
      path = [self];
    }
    if (self is T && predicate(self)) {
      return (node: self, path: path);
    }
    if (children != null) {
      for (final child in children!) {
        final result = child.find<T>(predicate, [...path, child]);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  String toMarkup({OrgSerializer? serializer}) {
    serializer ??= OrgSerializer();
    _toMarkupImpl(serializer);
    return serializer.toString();
  }

  void _toMarkupImpl(OrgSerializer buf);
}

sealed class OrgLeafNode extends OrgNode {
  @override
  List<OrgNode>? get children => null;
}

sealed class OrgParentNode extends OrgNode {
  OrgParentNode([String? id])
      : id = id ?? Random().nextInt(pow(2, 32).toInt()).toString();

  /// A unique ID for this node. Use this to identify nodes across edits via
  /// [OrgTree.edit], because [OrgParentNode]s can be recreated and thus will
  /// not be equal via [identical].
  final String id;

  @override
  List<OrgNode> get children;

  OrgParentNode fromChildren(List<OrgNode> children);
}

/// A node potentially containing [OrgSection]s
sealed class OrgTree extends OrgParentNode {
  OrgTree(this.content, [Iterable<OrgSection>? sections, super.id])
      : sections = List.unmodifiable(sections ?? const <OrgSection>[]);

  /// Leading content
  final OrgContent? content;

  /// Sections contained within this tree. These are also iterated by [children].
  final List<OrgSection> sections;

  /// Leading content, if present, followed by [sections]
  @override
  List<OrgNode> get children => [if (content != null) content!, ...sections];

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

  /// Obtain a zipper starting at the root of this tree. The zipper can be used
  /// to edit the tree; call [ZipperLocation.commit] to obtain a new tree with
  /// the edits applied.
  OrgZipper edit() => ZipperLocation.root(
        sectionP: (obj) => obj is OrgParentNode,
        node: this,
        getChildren: (obj) => obj.children,
        makeSection: (node, children) => node.fromChildren(children),
      );

  /// Obtain a zipper for the specified [node], which is presumed to be in this
  /// tree. Returns null if the node is not found. The zipper can be used to
  /// edit the tree; call [ZipperLocation.commit] to obtain a new tree with the
  /// edits applied.
  OrgZipper? editNode(OrgNode node) => edit().find(node);

  /// Get the ID properties from this section's PROPERTIES drawer, if any.
  List<String> get ids => getProperties(':ID:');

  /// Get the CUSTOM_ID properties from this section's PROPERTIES drawer, if
  /// any.
  List<String> get customIds => getProperties(':CUSTOM_ID:');

  /// Get the DIR properties from this section's PROPERTIES drawer, if any.
  List<String> get dirs => getProperties(':DIR:');

  /// Get the properties corresponding to [key] from this section's PROPERTIES
  /// drawer, if any.
  List<String> getProperties(String key) =>
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

  /// Find the immediate parent [OrgSection] or [OrgDocument] of the specified
  /// [node].
  OrgTree? findContainingTree<T extends OrgNode>(T node,
      {bool Function(OrgTree)? where}) {
    where ??= (_) => true;
    final found = find<T>((n) => identical(node, n));
    if (found == null) return null;
    final (node: _, :path) = found;
    for (final node in path.reversed) {
      if (node is OrgTree && where(node)) return node;
    }
    return null;
  }

  /// Get the directory in which attachments are expected to be found for this
  /// section. The behavior follows Org Mode defaults:
  /// `org-attach-use-inheritance` is `selective` and
  /// `org-use-property-inheritance` is `nil`, meaning that the relevant
  /// properties are not inherited from parent sections.
  String? get attachDir {
    final dir = dirs.lastOrNull;
    if (dir != null) return dir;
    final id = ids.lastOrNull;
    if (id != null && id.length >= 3) {
      return 'data/${id.substring(0, 2)}/${id.substring(2)}';
    }
    return null;
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
  void _toMarkupImpl(OrgSerializer buf) {
    for (final child in children) {
      buf.visit(child);
    }
  }
}

/// The top-level node representing a full Org document
class OrgDocument extends OrgTree {
  /// Parse an Org document in string form into an AST. If
  /// [interpretEmbeddedSettings] is true, the document may be parsed a second
  /// time in order to apply detected settings.
  factory OrgDocument.parse(
    String text, {
    bool interpretEmbeddedSettings = false,
  }) {
    var parsed = org.parse(text).value as OrgDocument;

    if (interpretEmbeddedSettings) {
      final todoSettings = extractTodoSettings(parsed);
      if (todoSettings.any((s) => s != defaultTodoStates)) {
        final parser = OrgParserDefinition(todoStates: todoSettings).build();
        parsed = parser.parse(text).value as OrgDocument;
      }
    }

    return parsed;
  }

  OrgDocument(super.content, super.sections, [super.id]);

  @override
  String toString() => 'OrgDocument';

  OrgDocument copyWith({
    OrgContent? content,
    Iterable<OrgSection>? sections,
    String? id,
  }) =>
      OrgDocument(
        content ?? this.content,
        sections ?? this.sections,
        id ?? this.id,
      );

  @override
  OrgDocument fromChildren(List<OrgNode> children) {
    if (children.isEmpty) {
      return copyWith(content: null, sections: []);
    }
    final content =
        children.first is OrgContent ? children.first as OrgContent : null;
    final sections = content == null ? children : children.skip(1);
    return copyWith(content: content, sections: sections.cast());
  }
}

/// An Org headline, like
///
/// ```
/// **** TODO [#A] COMMENT Title :tag1:tag2:
/// ```
class OrgHeadline extends OrgParentNode {
  OrgHeadline(
    this.stars,
    this.keyword,
    this.priority,
    this.title,
    this.rawTitle,
    ({String leading, Iterable<String> values, String trailing})? tags,
    this.trailing, [
    super.id,
  ]) : tags = tags == null
            ? null
            : (
                leading: tags.leading,
                values: List.unmodifiable(tags.values),
                trailing: tags.trailing
              );

  /// Headline stars, like `*** `. Includes trailing spaces.
  final ({String value, String trailing}) stars;

  /// Headline keyword, like `TODO`. [done] indicates whether the keyword
  /// represents an in-progress state or a done state (as in
  /// `org-done-keywords`). See also [OrgTodoStates].
  final ({String value, bool done, String trailing})? keyword;

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
  OrgHeadline fromChildren(List<OrgNode> children) =>
      copyWith(title: children.firstOrNull as OrgContent?);

  /// Cycle todo state like (null) -> TODO -> DONE -> (null). Uses
  /// [defaultTodoStates] if none provided. If the [keyword] value is not found
  /// in the states then will throw [ArgumentError].
  OrgHeadline cycleTodo([List<OrgTodoStates>? todoStates]) {
    todoStates ??= [defaultTodoStates];

    final allStates = todoStates.fold(
        <String>[],
        (acc, e) => acc
          ..addAll(e.todo)
          ..addAll(e.done));
    final currStateIdx =
        keyword == null ? -1 : allStates.indexOf(keyword!.value);
    if (keyword != null && currStateIdx == -1) {
      throw ArgumentError(
          'current keyword ${keyword!.value} not in todo settings');
    }
    if (currStateIdx == allStates.length - 1) {
      return OrgHeadline(
          stars, null, priority, title, rawTitle, tags, trailing, id);
    }
    final nextState = allStates[currStateIdx + 1];
    return copyWith(keyword: (
      value: nextState,
      done: todoStates.any((e) => e.done.contains(nextState)),
      trailing: keyword?.trailing ?? ' '
    ));
  }

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
  void _toMarkupImpl(OrgSerializer buf) {
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
    if (title != null) buf.visit(title!);
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

  OrgHeadline copyWith({
    ({String value, String trailing})? stars,
    ({String value, bool done, String trailing})? keyword,
    ({String leading, String value, String trailing})? priority,
    OrgContent? title,
    String? rawTitle,
    ({String leading, List<String> values, String trailing})? tags,
    String? trailing,
    String? id,
  }) =>
      OrgHeadline(
        stars ?? this.stars,
        keyword ?? this.keyword,
        priority ?? this.priority,
        title ?? this.title,
        rawTitle ?? this.rawTitle,
        tags ?? this.tags,
        trailing ?? this.trailing,
        id ?? this.id,
      );
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
    super.content, [
    super.sections,
    super.id,
  ]);
  final OrgHeadline headline;

  /// The section's tags. Convenience accessor for tags of [headline].
  List<String> get tags => headline.tags?.values ?? const [];

  @override
  List<OrgNode> get children => [headline, ...super.children];

  @override
  OrgSection fromChildren(List<OrgNode> children) {
    final headline = children.first as OrgHeadline;
    if (children.length < 2) {
      return copyWith(headline: headline);
    }
    final content =
        children[1] is OrgContent ? children[1] as OrgContent : null;
    final sections = content == null ? children.skip(1) : children.skip(2);
    return copyWith(
      headline: headline,
      content: content,
      sections: sections.cast(),
    );
  }

  int get level => headline.level;

  /// A section may be empty if it has no content or sub-sections
  bool get isEmpty => content == null && sections.isEmpty;

  OrgSection copyWith({
    OrgHeadline? headline,
    OrgContent? content,
    Iterable<OrgSection>? sections,
    String? id,
  }) =>
      OrgSection(
        headline ?? this.headline,
        content ?? this.content,
        sections ?? this.sections,
        id ?? this.id,
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

  // FIXME(aaron): This appears to be a false positive
  // ignore: unused_element
  void _toMarkupImpl(OrgSerializer buf) {
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
class OrgContent extends OrgParentNode {
  OrgContent(Iterable<OrgNode> children, [super.id])
      : children = children.length == 1 && children.firstOrNull is OrgContent
            ? (children.first as OrgContent).children
            : List.unmodifiable(children);

  @override
  final List<OrgNode> children;

  @override
  OrgContent fromChildren(List<OrgNode> children) =>
      copyWith(children: children);

  @override
  bool contains(Pattern pattern) =>
      children.any((child) => child.contains(pattern));

  @override
  String toString() => 'OrgContent';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    for (final child in children) {
      buf.visit(child);
    }
  }

  OrgContent copyWith({List<OrgNode>? children, String? id}) =>
      OrgContent(children ?? this.children, id ?? this.id);
}

/// Plain text that has no markup
class OrgPlainText extends OrgLeafNode with SingleContentElement {
  OrgPlainText(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgPlainText';
}

/// A link, like
/// ```
/// https://example.com
/// ```
class OrgLink extends OrgLeafNode {
  OrgLink(this.location);

  /// Where the link points
  final String location;

  @override
  bool contains(Pattern pattern) {
    return location.contains(pattern);
  }

  @override
  String toString() => 'OrgLink';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf.write(location);
  }
}

/// A bracketed link, like
/// ```
/// [[https://example.com][An example]]
/// ```
/// or
/// ```
/// [[https://example.com]]
/// ```
class OrgBracketLink extends OrgLink {
  OrgBracketLink(super.location, this.description);

  /// The user-visible text
  final String? description;

  @override
  bool contains(Pattern pattern) {
    return super.contains(pattern) ||
        description != null && description!.contains(pattern);
  }

  @override
  String toString() => 'OrgLink';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write('[[')
      ..write(location
          // Backslash must be first
          .replaceAll(r'\', r'\\')
          .replaceAll(r'[', r'\[')
          .replaceAll(r']', r'\]'));
    if (description != null) {
      buf
        ..write('][')
        ..write(description!
            .replaceAll(']]', ']\u200b]')
            .replaceAll(RegExp(r']$'), ']\u200b'));
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
class OrgMarkup extends OrgLeafNode {
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
  void _toMarkupImpl(OrgSerializer buf) {
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
class OrgMacroReference extends OrgLeafNode with SingleContentElement {
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
class OrgMeta extends OrgLeafNode with IndentedElement {
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
  void _toMarkupImpl(OrgSerializer buf) {
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
class OrgBlock extends OrgParentNode with IndentedElement {
  OrgBlock(
    this.indent,
    this.header,
    this.body,
    this.footer,
    this.trailing, [
    super.id,
  ]);

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
  OrgBlock fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single);

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);

  @override
  String toString() => 'OrgBlock';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(header)
      ..visit(body)
      ..write(footer)
      ..write(trailing);
  }

  OrgBlock copyWith({
    String? indent,
    String? header,
    OrgNode? body,
    String? footer,
    String? trailing,
    String? id,
  }) =>
      OrgBlock(
        indent ?? this.indent,
        header ?? this.header,
        body ?? this.body,
        footer ?? this.footer,
        trailing ?? this.trailing,
        id ?? this.id,
      );
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
class OrgTable extends OrgParentNode with IndentedElement {
  OrgTable(Iterable<OrgTableRow> rows, this.trailing, [super.id])
      : rows = List.unmodifiable(rows);

  final List<OrgTableRow> rows;

  @override
  List<OrgNode> get children => rows;

  @override
  OrgTable fromChildren(List<OrgNode> children) =>
      copyWith(rows: children.cast());

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
    final emptyCount = cells.where((c) => c.isEmpty).length;
    final nonEmptyCount = totalCount - emptyCount;
    final numberCount = cells.where((c) => c.isNumeric).length;
    return numberCount / nonEmptyCount >= _orgTableNumberFraction;
  }

  @override
  bool contains(Pattern pattern) => rows.any((row) => row.contains(pattern));

  @override
  String toString() => 'OrgTable';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    for (final row in rows) {
      buf.visit(row);
    }
    buf.write(trailing);
  }

  OrgTable copyWith({
    Iterable<OrgTableRow>? rows,
    String? trailing,
    String? id,
  }) {
    return OrgTable(
      rows ?? this.rows,
      trailing ?? this.trailing,
      id ?? this.id,
    );
  }
}

sealed class OrgTableRow extends OrgParentNode with IndentedElement {
  OrgTableRow(this.indent, this.trailing, [super.id]);

  @override
  final String indent;
  @override
  final String trailing;

  @override
  String toString() => runtimeType.toString();
}

class OrgTableDividerRow extends OrgTableRow {
  OrgTableDividerRow(super.indent, this.content, super.trailing, [super.id]);

  @override
  bool contains(Pattern pattern) => false;

  final String content;

  @override
  List<OrgNode> get children => [];

  @override
  OrgTableDividerRow fromChildren(List<OrgNode> children) => copyWith();

  @override
  String toString() => 'OrgTableDividerRow';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(content)
      ..write(trailing);
  }

  OrgTableDividerRow copyWith({
    String? indent,
    String? content,
    String? trailing,
    String? id,
  }) {
    return OrgTableDividerRow(
      indent ?? this.indent,
      content ?? this.content,
      trailing ?? this.trailing,
      id ?? this.id,
    );
  }
}

class OrgTableCellRow extends OrgTableRow {
  OrgTableCellRow(
    super.indent,
    Iterable<OrgTableCell> cells,
    super.trailing, [
    super.id,
  ]) : cells = List.unmodifiable(cells);

  final List<OrgTableCell> cells;

  @override
  List<OrgNode> get children => cells;

  @override
  OrgTableCellRow fromChildren(List<OrgNode> children) =>
      copyWith(cells: children.cast());

  int get cellCount => cells.length;

  @override
  bool contains(Pattern pattern) => cells.any((cell) => cell.contains(pattern));

  @override
  String toString() => 'OrgTableCellRow';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write('|');
    for (final cell in cells) {
      buf.visit(cell);
    }
    buf.write(trailing);
  }

  OrgTableCellRow copyWith({
    String? indent,
    Iterable<OrgTableCell>? cells,
    String? trailing,
    String? id,
  }) =>
      OrgTableCellRow(
        indent ?? this.indent,
        cells ?? this.cells,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

class OrgTableCell extends OrgParentNode {
  OrgTableCell(this.leading, this.content, this.trailing, [super.id]);

  final String leading;
  final OrgContent content;
  final String trailing;

  @override
  List<OrgNode> get children => [content];

  @override
  OrgTableCell fromChildren(List<OrgNode> children) =>
      copyWith(content: children.single as OrgContent);

  bool get isEmpty => content.children.isEmpty;

  bool get isNumeric {
    if (content.children.length == 1) {
      final onlyContent = content.children.first;
      if (onlyContent is OrgPlainText) {
        return _orgTableNumberRegexp.hasMatch(onlyContent.content);
      }
    }
    return false;
  }

  @override
  bool contains(Pattern pattern) {
    return content.contains(pattern);
  }

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..visit(content)
      ..write(trailing);
  }

  @override
  String toString() => 'OrgTableCell';

  OrgTableCell copyWith({
    String? leading,
    OrgContent? content,
    String? trailing,
    String? id,
  }) {
    return OrgTableCell(
      leading ?? this.leading,
      content ?? this.content,
      trailing ?? this.trailing,
      id ?? this.id,
    );
  }
}

// Default number-detecting regexp from org-mode 20200504, converted with:
//   (kill-new (rxt-elisp-to-pcre org-table-number-regexp))
final _orgTableNumberRegexp = RegExp(
    r'^([><]?[.\^+\-0-9]*[0-9][:%)(xDdEe.\^+\-0-9]*|[><]?[+\-]?0[Xx][.[:xdigit:]]+|[><]?[+\-]?[0-9]+#[.A-Za-z0-9]+|nan|[u+\-]?inf)$');

// Default fraction of non-empty cells in a column to make the column
// right-aligned. From org-mode 20200504.
const _orgTableNumberFraction = 0.5;

/// A timestamp, like `[2020-05-05 Tue]`
class OrgTimestamp extends OrgLeafNode with SingleContentElement {
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
class OrgKeyword extends OrgLeafNode with SingleContentElement {
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
class OrgPlanningLine extends OrgParentNode with IndentedElement {
  OrgPlanningLine(
    this.indent,
    this.keyword,
    this.body,
    this.trailing, [
    super.id,
  ]);

  @override
  final String indent;
  final OrgKeyword keyword;
  final OrgContent body;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [keyword, body];

  @override
  OrgPlanningLine fromChildren(List<OrgNode> children) => copyWith(
        keyword: children[0] as OrgKeyword,
        body: children[1] as OrgContent,
      );

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      keyword.contains(pattern) ||
      body.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgPlanningLine';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..visit(keyword)
      ..visit(body)
      ..write(trailing);
  }

  OrgPlanningLine copyWith({
    String? indent,
    OrgKeyword? keyword,
    OrgContent? body,
    String? trailing,
    String? id,
  }) =>
      OrgPlanningLine(
        indent ?? this.indent,
        keyword ?? this.keyword,
        body ?? this.body,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

/// A fixed-width area, like
/// ```
/// : result of source block, or whatever
/// ```
class OrgFixedWidthArea extends OrgLeafNode with IndentedElement {
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
  void _toMarkupImpl(OrgSerializer buf) {
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
class OrgList extends OrgParentNode with IndentedElement {
  OrgList(Iterable<OrgListItem> items, this.trailing, [super.id])
      : items = List.unmodifiable(items);
  final List<OrgListItem> items;

  @override
  String get indent => items.isEmpty ? '' : items.first.indent;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => items;

  @override
  OrgList fromChildren(List<OrgNode> children) =>
      copyWith(items: children.cast());

  @override
  bool contains(Pattern pattern) => items.any((item) => item.contains(pattern));

  @override
  String toString() => 'OrgList';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    for (final item in items) {
      buf.visit(item);
    }
    buf.write(trailing);
  }

  OrgList copyWith({
    Iterable<OrgListItem>? items,
    String? trailing,
    String? id,
  }) =>
      OrgList(
        items ?? this.items,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

sealed class OrgListItem extends OrgParentNode {
  OrgListItem(this.indent, this.bullet, this.checkbox, this.body, [super.id]);

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

  OrgListItem toggleCheckbox() {
    final toggledCheckbox =
        switch (checkbox) { '[X]' => '[ ]', '[ ]' => '[X]', _ => checkbox };
    final self = this;
    // TODO(aaron): Is there no better way to do this?
    return switch (self) {
      OrgListOrderedItem() => self.copyWith(checkbox: toggledCheckbox),
      OrgListUnorderedItem() => self.copyWith(checkbox: toggledCheckbox),
    };
  }
}

/// An unordered list item, like
/// ```
/// - foo
/// ```
class OrgListUnorderedItem extends OrgListItem {
  OrgListUnorderedItem(
    super.indent,
    super.bullet,
    super.checkbox,
    this.tag,
    super.body, [
    super.id,
  ]);

  final ({OrgContent value, String delimiter})? tag;

  @override
  List<OrgNode> get children =>
      [if (tag != null) tag!.value, ...super.children];

  @override
  OrgListUnorderedItem fromChildren(List<OrgNode> children) {
    if (children.length == 1) {
      return copyWith(body: children.single as OrgContent);
    } else {
      return copyWith(
        tag: (
          value: children[0] as OrgContent,
          delimiter: tag?.delimiter ?? ' '
        ),
        body: children[1] as OrgContent,
      );
    }
  }

  @override
  bool contains(Pattern pattern) {
    final tag = this.tag;
    return tag != null &&
            (tag.value.contains(pattern) || tag.delimiter.contains(pattern)) ||
        super.contains(pattern);
  }

  @override
  String toString() => 'OrgListUnorderedItem';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(bullet);
    // TODO(aaron): Retain actual separating white space
    if (checkbox != null) {
      buf
        ..write(checkbox!)
        ..write(' ');
    }
    if (tag != null) {
      buf
        ..visit(tag!.value)
        ..write(tag!.delimiter);
    }
    if (body != null) buf.visit(body!);
  }

  OrgListUnorderedItem copyWith({
    String? indent,
    String? bullet,
    String? checkbox,
    ({OrgContent value, String delimiter})? tag,
    OrgContent? body,
    String? id,
  }) =>
      OrgListUnorderedItem(
        indent ?? this.indent,
        bullet ?? this.bullet,
        checkbox ?? this.checkbox,
        tag ?? this.tag,
        body ?? this.body,
        id ?? this.id,
      );
}

/// An ordered list item, like
/// ```
/// 1. foo
/// ```
class OrgListOrderedItem extends OrgListItem {
  OrgListOrderedItem(
    super.indent,
    super.bullet,
    this.counterSet,
    super.checkbox,
    super.body, [
    String? id,
  ]);

  final String? counterSet;

  @override
  bool contains(Pattern pattern) {
    final counterSet = this.counterSet;
    return counterSet != null && counterSet.contains(pattern) ||
        super.contains(pattern);
  }

  @override
  OrgListOrderedItem fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single as OrgContent);

  @override
  String toString() => 'OrgListOrderedItem';
  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(bullet);
    // TODO(aaron): Retain actual separating white space
    if (counterSet != null) {
      buf
        ..write(counterSet!)
        ..write(' ');
    }
    if (checkbox != null) {
      buf
        ..write(checkbox!)
        ..write(' ');
    }
    if (body != null) buf.visit(body!);
  }

  OrgListOrderedItem copyWith({
    String? indent,
    String? bullet,
    String? counterSet,
    String? checkbox,
    OrgContent? body,
    String? id,
  }) =>
      OrgListOrderedItem(
        indent ?? this.indent,
        bullet ?? this.bullet,
        counterSet ?? this.counterSet,
        checkbox ?? this.checkbox,
        body ?? this.body,
        id ?? this.id,
      );
}

class OrgParagraph extends OrgParentNode {
  OrgParagraph(this.indent, this.body, [super.id]);

  final String indent;
  final OrgContent body;

  @override
  List<OrgNode> get children => [body];

  @override
  OrgParagraph fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single as OrgContent);

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) || body.contains(pattern);

  @override
  String toString() => 'OrgParagraph';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..visit(body);
  }

  OrgParagraph copyWith({
    String? indent,
    OrgContent? body,
    String? id,
  }) =>
      OrgParagraph(
        indent ?? this.indent,
        body ?? this.body,
        id ?? this.id,
      );
}

/// A drawer, like
/// ```
/// :PROPERTIES:
/// :CUSTOM_ID: foobar
/// :END:
/// ```
class OrgDrawer extends OrgParentNode with IndentedElement {
  OrgDrawer(
    this.indent,
    this.header,
    this.body,
    this.footer,
    this.trailing, [
    super.id,
  ]);

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
  OrgDrawer fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single);

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
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(header)
      ..visit(body)
      ..write(footer)
      ..write(trailing);
  }

  OrgDrawer copyWith({
    String? indent,
    String? header,
    OrgNode? body,
    String? footer,
    String? trailing,
    String? id,
  }) =>
      OrgDrawer(
        indent ?? this.indent,
        header ?? this.header,
        body ?? this.body,
        footer ?? this.footer,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

/// A property in a drawer, like
/// ```
/// :CUSTOM_ID: foobar
/// ```
class OrgProperty extends OrgLeafNode with IndentedElement {
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
  void _toMarkupImpl(OrgSerializer buf) {
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
class OrgFootnote extends OrgParentNode {
  OrgFootnote(this.marker, this.content, [super.id])
      : assert(marker.isDefinition);

  final OrgFootnoteReference marker;
  final OrgContent content;

  @override
  List<OrgNode> get children => [marker, content];

  @override
  OrgFootnote fromChildren(List<OrgNode> children) => copyWith(
      marker: children[0] as OrgFootnoteReference,
      content: children[1] as OrgContent);

  @override
  bool contains(Pattern pattern) =>
      marker.contains(pattern) || content.contains(pattern);

  @override
  String toString() => 'OrgFootnote';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..visit(marker)
      ..visit(content);
  }

  OrgFootnote copyWith({
    OrgFootnoteReference? marker,
    OrgContent? content,
    String? id,
  }) =>
      OrgFootnote(
        marker ?? this.marker,
        content ?? this.content,
        id ?? this.id,
      );
}

/// A footnote reference, like `[fn:1]`
class OrgFootnoteReference extends OrgParentNode {
  OrgFootnoteReference.named(
    String leading,
    String name,
    String trailing, [
    String? id,
  ]) : this(false, leading, name, null, trailing, id);

  OrgFootnoteReference(
    this.isDefinition,
    this.leading,
    this.name,
    this.definition,
    this.trailing, [
    super.id,
  ]);

  final bool isDefinition;
  final String leading;
  final String? name;
  final ({String delimiter, OrgContent value})? definition;
  final String trailing;

  @override
  List<OrgNode> get children =>
      definition == null ? const [] : [definition!.value];

  @override
  OrgFootnoteReference fromChildren(List<OrgNode> children) =>
      copyWith(definition: (
        delimiter: definition?.delimiter ?? ':',
        value: children.single as OrgContent,
      ));

  @override
  bool contains(Pattern pattern) {
    final name = this.name;
    final definition = this.definition;
    return leading.contains(pattern) ||
        name != null && name.contains(pattern) ||
        definition != null && definition.delimiter.contains(pattern) ||
        definition != null && definition.value.contains(pattern) ||
        trailing.contains(pattern);
  }

  @override
  String toString() => 'OrgFootnoteReference';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(name ?? '')
      ..write(definition?.delimiter ?? '');
    if (definition != null) buf.visit(definition!.value);
    buf.write(trailing);
  }

  OrgFootnoteReference copyWith({
    bool? isDefinition,
    String? leading,
    String? name,
    ({String delimiter, OrgContent value})? definition,
    String? trailing,
    String? id,
  }) =>
      OrgFootnoteReference(
        isDefinition ?? this.isDefinition,
        leading ?? this.leading,
        name ?? this.name,
        definition ?? this.definition,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}

/// A citation like [cite:@key]
class OrgCitation extends OrgLeafNode {
  String leading;
  ({String leading, String value})? style;
  String delimiter;
  String body;
  String trailing;

  OrgCitation(
    this.leading,
    this.style,
    this.delimiter,
    this.body,
    this.trailing,
  );

  // TODO(aaron): This is dangerously close to needing its own parser
  List<String> getKeys() => body
      .split(';')
      .expand((token) => token.split(' '))
      .expand((token) => token.split(RegExp('(?=@)')))
      .where((token) => token.startsWith('@'))
      .map((token) => token.substring(1))
      .toList(growable: false);

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(style?.leading ?? '')
      ..write(style?.value ?? '')
      ..write(delimiter)
      ..write(body)
      ..write(trailing);
  }

  @override
  bool contains(Pattern pattern) {
    return leading.contains(pattern) ||
        style?.value.contains(pattern) == true ||
        delimiter.contains(pattern) ||
        body.contains(pattern) ||
        trailing.contains(pattern);
  }

  OrgCitation copyWith({
    String? leading,
    ({String leading, String value})? style,
    String? delimiter,
    String? body,
    String? trailing,
  }) {
    return OrgCitation(
      leading ?? this.leading,
      style ?? this.style,
      delimiter ?? this.delimiter,
      body ?? this.body,
      trailing ?? this.trailing,
    );
  }
}

/// A LaTeX block, like
/// ```
/// \begin{equation}
/// \nabla \cdot \mathbf{B} = 0
/// \end{equation}
/// ```
class OrgLatexBlock extends OrgLeafNode {
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
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(begin)
      ..write(content)
      ..write(end)
      ..write(trailing);
  }
}

/// An inline LaTeX snippet, like `$E=mc^2$`
class OrgLatexInline extends OrgLeafNode {
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
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leadingDecoration)
      ..write(content)
      ..write(trailingDecoration);
  }
}

/// An entity, like `\Omega`
class OrgEntity extends OrgLeafNode {
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
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(name)
      ..write(trailing);
  }
}

class OrgSubscript extends OrgLeafNode {
  OrgSubscript(this.leading, this.body);

  final String leading;
  final String body;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) || body.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(body);
  }
}

class OrgSuperscript extends OrgLeafNode {
  OrgSuperscript(this.leading, this.body);

  final String leading;
  final String body;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) || body.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(body);
  }
}

class OrgLocalVariables extends OrgLeafNode {
  OrgLocalVariables(
    this.start,
    Iterable<({String prefix, String content, String suffix})> content,
    this.end,
  ) : entries = List.unmodifiable(content);

  final String start;
  final List<({String prefix, String content, String suffix})> entries;
  final String end;

  String get contentString => entries.map((line) => line.content).join('\n');

  @override
  bool contains(Pattern pattern) =>
      start.contains(pattern) ||
      entries.any((line) => line.content.contains(pattern)) ||
      end.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf.write(start);
    for (final entry in entries) {
      buf
        ..write(entry.prefix)
        ..write(entry.content)
        ..write(entry.suffix);
    }
    buf.write(end);
  }
}

class OrgPgpBlock extends OrgLeafNode with IndentedElement {
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
}

// This is an abstract class so that it can be sent to an isolate for processing
abstract class DecryptedContentSerializer {
  String toMarkup(OrgDecryptedContent content);
}

class OrgDecryptedContent extends OrgTree {
  static OrgDecryptedContent fromDecryptedResult(
    String cleartext,
    DecryptedContentSerializer serializer,
  ) {
    final parsed = OrgDocument.parse(cleartext);
    return OrgDecryptedContent(
      serializer,
      parsed.content,
      parsed.sections,
      parsed.id,
    );
  }

  OrgDecryptedContent(
    this.serializer,
    super.content,
    super.sections,
    super.id,
  );

  final DecryptedContentSerializer serializer;

  @override
  void _toMarkupImpl(OrgSerializer buf) => buf.write(serializer.toMarkup(this));

  String toCleartextMarkup({OrgSerializer? serializer}) {
    serializer ??= OrgSerializer();
    for (final child in children) {
      serializer.visit(child);
    }
    return serializer.toString();
  }

  @override
  String toString() => 'OrgDecryptedContent';

  @override
  List<OrgNode> get children => [if (content != null) content!, ...sections];

  @override
  OrgParentNode fromChildren(List<OrgNode> children) {
    final content =
        children.first is OrgContent ? children.first as OrgContent : null;
    final sections = content == null ? children : children.skip(1);
    return copyWith(content: content, sections: sections.cast());
  }

  OrgDecryptedContent copyWith({
    DecryptedContentSerializer? serializer,
    OrgContent? content,
    Iterable<OrgSection>? sections,
    String? id,
  }) =>
      OrgDecryptedContent(
        serializer ?? this.serializer,
        content ?? this.content,
        sections ?? this.sections,
        id ?? this.id,
      );
}

class OrgComment extends OrgLeafNode {
  OrgComment(this.indent, this.start, this.content);

  final String indent;
  final String start;
  final String content;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      start.contains(pattern) ||
      content.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(start)
      ..write(content);
  }
}
