part of '../model.dart';

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
