part of '../model.dart';

// Default number-detecting regexp from org-mode 20200504, converted with:
//   (kill-new (rxt-elisp-to-pcre org-table-number-regexp))
final _orgTableNumberRegexp = RegExp(
    r'^([><]?[.\^+\-0-9]*[0-9][:%)(xDdEe.\^+\-0-9]*|[><]?[+\-]?0[Xx][.[0-9a-fA-F]]+|[><]?[+\-]?[0-9]+#[.A-Za-z0-9]+|nan|[u+\-]?inf)$');

// Default fraction of non-empty cells in a column to make the column
// right-aligned. From org-mode 20200504.
const _orgTableNumberFraction = 0.5;

/// A table, like
/// ```
/// | Foo         |    Bar |  Baz |
/// |-------------+--------+------|
/// | Lorem ipsum | 30.000 |    1 |
/// | 123         |        |      |
/// ```
class OrgTable extends OrgParentNode with OrgElement {
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

sealed class OrgTableRow extends OrgParentNode {
  OrgTableRow(this.indent, this.trailing, [super.id]);

  final String indent;
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

  bool get isNumeric => _isNumeric(content);

  bool _isNumeric(OrgContent content) {
    if (content.children.length != 1) return false;
    final onlyContent = content.children.first;
    return switch (onlyContent) {
      // This is maybe a bit hacky to handle just these specific types, but we
      // are trying to avoid serializing back to markup here.
      OrgMarkup() => _isNumeric(onlyContent.content),
      OrgPlainText() => _orgTableNumberRegexp.hasMatch(onlyContent.content),
      _ => false,
    };
  }

  @override
  bool contains(Pattern pattern) => content.contains(pattern);

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
