part of '../model.dart';

/// A list, like
/// ```
/// - foo
/// - bar
///   - baz
/// ```
class OrgList extends OrgParentNode with OrgElement {
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
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      bullet.contains(pattern) ||
      checkbox?.contains(pattern) == true ||
      body?.contains(pattern) == true;

  @override
  String toString() => runtimeType.toString();

  OrgListItem toggleCheckbox({bool add = false}) {
    final toggledCheckbox = switch (checkbox) {
      '[X]' => '[ ]',
      '[ ]' => '[X]',
      _ => add ? '[ ]' : checkbox
    };
    final self = this;
    // TODO(aaron): Is there no better way to do this?
    return switch (self) {
      OrgListOrderedItem() => self.copyWith(checkbox: toggledCheckbox),
      OrgListUnorderedItem() => self.copyWith(checkbox: toggledCheckbox),
    };
  }

  OrgListItem parentCopyWith({
    String? indent,
    String? bullet,
    String? checkbox,
    OrgContent? body,
  }) {
    final self = this;
    return switch (self) {
      OrgListOrderedItem() => self.copyWith(
          indent: indent,
          bullet: bullet,
          checkbox: checkbox,
          body: body,
        ),
      OrgListUnorderedItem() => self.copyWith(
          indent: indent,
          bullet: bullet,
          checkbox: checkbox,
          body: body,
        ),
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
  bool contains(Pattern pattern) =>
      tag?.value.contains(pattern) == true ||
      tag?.delimiter.contains(pattern) == true ||
      super.contains(pattern);

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
