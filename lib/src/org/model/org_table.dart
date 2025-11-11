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
          .length ==
      1;

  /// The maximum number of columns in any row of the table
  int get columnCount {
    final cellRows = rows
        .whereType<OrgTableCellRow>()
        .map((row) => row.cellCount)
        .toList(growable: false);
    return cellRows.isEmpty ? 0 : cellRows.reduce(max);
  }

  /// Determine whether the column number [colIdx] should be treated as a
  /// numeric column. A certain percentage of non-numeric cells are tolerated.
  ///
  /// This value is not meaningful if [colIdx] is out of range for the table.
  bool columnIsNumeric(int colIdx) {
    final cells = rows
        .whereType<OrgTableCellRow>()
        .map((row) => colIdx >= row.cells.length ? null : row.cells[colIdx])
        .toList(growable: false);
    if (cells.every((c) => c == null)) {
      throw RangeError.range(
          colIdx, 0, columnCount, 'No such column in any row', null);
    }
    final totalCount = cells.length;
    final emptyCount = cells.where((c) => c == null || c.isEmpty).length;
    final nonEmptyCount = totalCount - emptyCount;
    final numberCount = cells.where((c) => c?.isNumeric == true).length;
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
  bool get isNotEmpty => !isEmpty;

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

  // TODO(aaron): Ideally _toPlainTextImpl here would fix up the table layout to
  // make up for width changes when serializing to plain text.

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
