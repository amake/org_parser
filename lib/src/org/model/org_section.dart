part of '../model.dart';

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

  String get elementName => level >= 15 ? 'inlinetask' : 'section';

  final OrgHeadline headline;

  /// The section's tags. Convenience accessor for tags of [headline].
  List<String> get tags => headline.tags?.values ?? const [];

  /// Returns the tags of this section and all parent sections.
  List<String> tagsWithInheritance(OrgTree doc) =>
      doc
          .find((node) => identical(node, this))
          ?.path
          .whereType<OrgSection>()
          .fold<List<String>>([], (acc, node) => acc..addAll(node.tags)) ??
      const [];

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

  @override
  int get level => headline.level;

  /// A section may be empty if it has no content or sub-sections
  bool get isEmpty => content == null && sections.isEmpty;

  OrgSection cycleTodo({
    List<OrgTodoStates>? todoStates,
    DateTime? now,
    bool logDone = false,
  }) {
    now ??= DateTime.now();
    todoStates ??= [defaultTodoStates];
    var hasRepeat = false;
    var content = this.content;
    final previousKeyword = this.headline.keyword;
    var headline = this.headline.cycleTodo(todoStates);

    (bool, OrgZipper?) visitor(OrgZipper location) {
      final node = location.node;
      if (node is OrgTimestamp && node.isActive && node.repeats) {
        hasRepeat = true;
        location = location.replace(node.bumpRepetition(now));
      }
      return (true, location);
    }

    headline = headline.edit().visit(visitor).commit<OrgHeadline>();
    content = content?.edit().visit(visitor).commit<OrgContent>();

    if (!hasRepeat) {
      final nowDone = headline.keyword?.done == true;
      final wasAlreadyDone = previousKeyword?.done == true;
      if (logDone && nowDone && !wasAlreadyDone) {
        return copyWith(
          headline: headline,
          content: content,
        ).ensureDoneTimestamp(now: now);
      } else if (logDone && !nowDone && wasAlreadyDone) {
        return copyWith(
          headline: headline,
          content: content,
        ).removeDoneTimestamp();
      } else {
        return copyWith(
          headline: headline,
          content: content,
        );
      }
    }

    String? finalKeywordValue;
    if (headline.keywordIsEndState(todoStates)) {
      finalKeywordValue = headline.keyword?.value ?? '';
      headline = headline.withoutKeyword();
      if (todoStates.any((t) => t.todo.isNotEmpty)) {
        headline = headline.cycleTodo(todoStates);
      }
    }

    if (finalKeywordValue == null) {
      return copyWith(
        headline: headline,
        content: content,
      );
    }

    final indent = level > 0 ? ' ' * (level + 1) : '';
    final timestamp =
        OrgSimpleTimestamp('[', now.toOrgDate(), now.toOrgTime(), [], ']');
    final lastRepeat = OrgProperty(
        indent, ':LAST_REPEAT:', ' ', OrgContent([timestamp]), '\n');

    final note = OrgContent([
      // See org-log-note-headings
      OrgPlainText(
          'State ${'"$finalKeywordValue"'.padRight(12)} from ${'"${previousKeyword?.value ?? ''}"'.padRight(12)}'),
      timestamp,
      OrgPlainText('\n'),
    ]);

    return copyWith(
      headline: headline,
      content: content,
    ).setProperty<OrgSection>(lastRepeat).addLogNote(note);
  }

  OrgSection ensureDoneTimestamp({DateTime? now}) {
    now ??= DateTime.now();
    final timestamp =
        OrgSimpleTimestamp('[', now.toOrgDate(), now.toOrgTime(), [], ']');

    final found = content
        ?.find<OrgPlanningEntry>((node) => node.keyword.content == 'CLOSED:');
    if (found != null) {
      final doneEntry = found.node.copyWith(value: timestamp);
      final newContent = content!
          .editNode(found.node)!
          .replace(doneEntry)
          .commit<OrgContent>();
      return _ensureContent(content: newContent);
    }

    final doneEntry = OrgPlanningEntry(
      OrgPlanningKeyword('CLOSED:'),
      ' ',
      timestamp,
    );

    final scheduled = content?.find<OrgPlanningEntry>(
        (node) => node.keyword.content == 'SCHEDULED:');
    if (scheduled != null) {
      final newContent = content!
          .editNode(scheduled.node)!
          .insertLeft(doneEntry)
          .insertLeft(OrgPlainText(' '))
          .commit<OrgContent>();
      return _ensureContent(content: newContent);
    }

    // TODO(aaron): Adapting the indent is actually not default behavior; it is
    // controlled by `org-adapt-indentation` and this implementation is assuming
    // that it is non-nil, but the default is nil.
    final indent = level > 0 ? ' ' * (level + 1) : '';
    final paragraph = OrgParagraph(indent, OrgContent([doneEntry]), '\n');

    if (content == null) {
      final newContent = OrgContent([paragraph]);
      return _ensureContent(content: newContent);
    }

    return _ensureContent(
        content: content!.copyWith(
      children: [paragraph, ...content!.children],
    ));
  }

  OrgSection removeDoneTimestamp() {
    if (content == null) return this;

    final found = content!
        .find<OrgPlanningEntry>((node) => node.keyword.content == 'CLOSED:');
    if (found == null) return this;

    var newContent = content!.editNode(found.node)!.delete();
    if (newContent.node case OrgContent(children: [])) {
      // If the containing paragraph is now empty, delete it as well
      final parent = newContent.goUp();
      if (parent.node case OrgParagraph()) {
        newContent = parent.delete();
      }
    } else if (newContent.node case OrgPlainText(content: final rightText)) {
      // If the CLOSED: entry had a trailing SCHEDULED: entry, trim the spaces
      // between them
      if (rightText.trim().isEmpty && newContent.canGoRight()) {
        final rightNode = newContent.goRight().node;
        if (rightNode is OrgPlanningEntry &&
            rightNode.keyword.content == 'SCHEDULED:') {
          newContent = newContent.delete();
        }
      }
    }
    return _ensureContent(content: newContent.commit<OrgContent>());
  }

  OrgSection addLogNote(OrgContent note) {
    // TODO(aaron): Adapting the indent is actually not default behavior; it is
    // controlled by `org-adapt-indentation` and this implementation is assuming
    // that it is non-nil, but the default is nil.
    final indent = level > 0 ? ' ' * (level + 1) : '';
    final logItem = OrgListUnorderedItem(indent, '- ', null, null, note);
    final existingLog = _getLogList();
    if (existingLog != null) {
      final newLog = existingLog.copyWith(
        items: [logItem, ...existingLog.items],
      );
      final newContent =
          content!.editNode(existingLog)!.replace(newLog).commit<OrgContent>();
      return _ensureContent(content: newContent);
    }

    final log = OrgList([logItem], '');

    if (content == null) {
      return _ensureContent(content: OrgContent([log]));
    }

    final properties = content!.find<OrgDrawer>(
        (entry) => entry.header.trim().toUpperCase() == ':PROPERTIES:');

    // If there is a PROPERTIES drawer, insert the log after it
    if (properties != null) {
      final newContent = content!
          .editNode(properties.node)!
          .replace(properties.node.ensureTrailingNewLine())
          .insertRight(log)
          .commit<OrgContent>();
      return _ensureContent(content: newContent);
    }

    final planning = content!.find<OrgPlanningEntry>(
        (entry) => entry.keyword.content == 'SCHEDULED:');

    // If there are planning entries, insert the drawer after the first entry's
    // paragraph.
    if (planning != null) {
      final paragraph =
          planning.path.reversed.whereType<OrgParagraph>().singleOrNull;
      // Only skip past SCHEDULED: entry paragraph if it is immediately after
      // the headline (i.e., first child of content)
      if (paragraph != null && paragraph.body.children.first == planning.node) {
        final newContent = content!
            .editNode(paragraph)!
            .replace(paragraph.ensureTrailingNewLine())
            .insertRight(log)
            .commit<OrgContent>();
        return _ensureContent(content: newContent);
      }
    }

    // Otherwise, insert the log at the start of the content
    final newContent = content!.copyWith(
      children: [log, ...content!.children],
    );

    return _ensureContent(content: newContent);
  }

  OrgList? _getLogList() {
    if (content == null || content!.children.isEmpty) return null;
    final iter = content!.children.iterator;
    var node = iter.moveNext() ? iter.current : null;
    if (node is OrgParagraph) {
      final firstChild = node.body.children.firstOrNull;
      if (firstChild is OrgPlanningEntry &&
          firstChild.keyword.content == 'SCHEDULED:') {
        node = iter.moveNext() ? iter.current : null;
      }
    }
    if (node is OrgDrawer &&
        node.header.trim().toUpperCase() == ':PROPERTIES:') {
      node = iter.moveNext() ? iter.current : null;
    }
    return node is OrgList ? node : null;
  }

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
  OrgSection _ensureContent({required OrgContent content}) =>
      copyWith(headline: headline.ensureTrailingNewLine(), content: content);

  @override
  bool contains(Pattern pattern, {bool includeChildren = true}) =>
      headline.contains(pattern) ||
      super.contains(pattern, includeChildren: includeChildren);

  @override
  String toString() => 'OrgSection';

  OrgSection ensureTrailingNewLine() {
    return content == null
        ? copyWith(headline: headline.ensureTrailingNewLine())
        : copyWith(content: content!.ensureTrailingNewLine());
  }
}
