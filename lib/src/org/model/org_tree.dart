part of '../model.dart';

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
      final haveTodoSettings = todoSettings.any((s) => s != defaultTodoStates);
      final radioTargets = extractRadioTargets(parsed);
      final haveRadioTargets = radioTargets.any((t) => t.isNotEmpty);
      if (haveTodoSettings || haveRadioTargets) {
        final parser = OrgParserDefinition(
          todoStates: haveTodoSettings ? todoSettings : null,
          radioTargets:
              haveRadioTargets ? radioTargets.toList(growable: false) : null,
        ).build();
        parsed = parser.parse(text).value as OrgDocument;
      }
    }

    return parsed;
  }

  OrgDocument(super.content, super.sections, [super.id]);

  @override
  int get level => 0;

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
  OrgDocument _ensureContent({required OrgContent content}) =>
      copyWith(content: content);

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
