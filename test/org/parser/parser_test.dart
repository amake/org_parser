import 'dart:io';

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('parser complete', () {
    final parser = org;
    test('example document', () {
      const doc = '''An introduction.

* A Headline

  Some text. *bold*

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''';
      final parsed = parser.parse(doc);
      expect(parsed, isA<Success<dynamic>>());
      final document = parsed.value as OrgDocument;
      final paragraph = document.content!.children[0] as OrgParagraph;
      final text = paragraph.body.children[0] as OrgPlainText;
      expect(text.content, 'An introduction.');
      final topSection = document.sections[0];
      final topContent0 =
          topSection.headline.title!.children[0] as OrgPlainText;
      expect(topContent0.content, 'A Headline');
      expect(topSection.sections.length, 2);
      expect(document.contains('bold'), isTrue);
      expect(
          document.contains('*bold*'), isFalse); // TODO(aaron): could improve?
      expect(document.contains(RegExp(r'Add')), isTrue);
      expect(document.contains(RegExp(r'\bAdd\b')), isFalse);
    });
    test('footnotes', () {
      final parser = org;
      final result = parser.parse('''[fn:1] foo bar

biz baz

[fn:2] bazinga


bazoonga''');
      expect(result, isA<Success<dynamic>>());
      final document = result.value as OrgDocument;
      final footnote0 = document.content!.children[0] as OrgFootnote;
      expect(footnote0.marker.name, '1');
      final footnote0Body = footnote0.content.children[0] as OrgPlainText;
      expect(footnote0Body.content, ' foo bar');
      final paragraph0 = document.content!.children[1] as OrgParagraph;
      final paragraph0Body0 = paragraph0.body.children[0] as OrgPlainText;
      expect(paragraph0Body0.content, 'biz baz');
      final footnote1 = document.content!.children[2] as OrgFootnote;
      final footnote1Body = footnote1.content.children[0] as OrgPlainText;
      expect(footnote1Body.content, ' bazinga');
      final paragraph1 = document.content!.children[3] as OrgParagraph;
      final paragraph1Body0 = paragraph1.body.children[0] as OrgPlainText;
      expect(paragraph1Body0.content, 'bazoonga');
    });
    test('footnotes containing meta lines', () {
      final parser = org;
      final result = parser.parse('''[fn:1] foo bar

#+bibliography: baz.bib''');
      expect(result, isA<Success<dynamic>>());
      final document = result.value as OrgDocument;
      final footnote = document.content!.children[0] as OrgFootnote;
      final footnoteBody0 = footnote.content.children[0] as OrgPlainText;
      expect(footnoteBody0.content, ' foo bar');
      final footnoteBody1 = document.content!.children[1] as OrgMeta;
      expect(footnoteBody1.keyword, '#+bibliography:');
    });
    group('https://github.com/amake/orgro/issues/16', () {
      test('case 1', () {
        final result = parser.parse('* AB:CD: foo');
        final document = result.value as OrgDocument;
        final section = document.sections[0];
        expect(section.headline.rawTitle, 'AB:CD: foo');
      });
      test('case 2', () {
        final result = parser.parse('* foo :AB:CD: bar');
        final document = result.value as OrgDocument;
        final section = document.sections[0];
        expect(section.headline.rawTitle, 'foo :AB:CD: bar');
      });
      test('case 3', () {
        final result = parser.parse('* foo:AB:CD:');
        final document = result.value as OrgDocument;
        final section = document.sections[0];
        expect(section.headline.rawTitle, 'foo:AB:CD:');
      });
    });
    test('https://github.com/amake/orgro/issues/51', () {
      final result = parser.parse('''**${' '}
* foo''');
      final document = result.value as OrgDocument;
      expect(document.sections.length, 2);
      expect(document.sections[0].headline.rawTitle, isNull);
      expect(document.sections[1].headline.rawTitle, 'foo');
    });
    test('https://github.com/amake/orgro/issues/75', () {
      final result = parser.parse(r'''* A $1
* B
1$''');
      final document = result.value as OrgDocument;
      expect(document.sections.length, 2);
      expect(document.sections[0].headline.rawTitle, r'A $1');
    });
    test('complex document', () {
      final result =
          parser.parse(File('test/org-syntax.org').readAsStringSync());
      expect(result, isA<Success<dynamic>>());
    });
    test('complex document 2', () {
      final result =
          parser.parse(File('test/org-manual.org').readAsStringSync());
      expect(result, isA<Success<dynamic>>());
    });
    test('readme example', () {
      final doc = OrgDocument.parse('''* TODO [#A] foo bar
        baz buzz''');
      expect(doc.sections[0].headline.keyword?.value, 'TODO');
    });
  });
}
