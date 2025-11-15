part of '../model.dart';

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
      return withoutKeyword();
    }
    final nextState = allStates[currStateIdx + 1];
    return copyWith(keyword: (
      value: nextState,
      done: todoStates.any((e) => e.done.contains(nextState)),
      trailing: keyword?.trailing ?? ' '
    ));
  }

  @override
  bool contains(Pattern pattern) =>
      stars.value.contains(pattern) ||
      stars.trailing.contains(pattern) ||
      keyword?.value.contains(pattern) == true ||
      keyword?.trailing.contains(pattern) == true ||
      priority?.leading.contains(pattern) == true ||
      priority?.value.contains(pattern) == true ||
      priority?.trailing.contains(pattern) == true ||
      rawTitle?.contains(pattern) == true ||
      tags?.leading.contains(pattern) == true ||
      tags?.values.any((tag) => tag.contains(pattern)) == true ||
      tags?.trailing.contains(pattern) == true ||
      trailing?.contains(pattern) == true;

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

  OrgHeadline withoutKeyword() => keyword == null
      ? this
      : OrgHeadline(stars, null, priority, title, rawTitle, tags, trailing);
}
