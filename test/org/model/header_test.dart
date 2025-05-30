import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('header', () {
    final definition = OrgParserDefinition();
    final parser = definition.buildFrom(definition.headline()).end();
    test('full', () {
      final markup = '** TODO [#A] Title foo bar :biz:baz:';
      final result = parser.parse(markup);
      final headline = result.value as OrgHeadline;
      expect(headline.contains('Title foo'), isTrue);
      expect(headline.contains('あ'), isFalse);
      expect(headline.toMarkup(), markup);
    });
    test('empty', () {
      final markup = '* ';
      final result = parser.parse(markup);
      final headline = result.value as OrgHeadline;
      expect(headline.contains('*'), isTrue);
      expect(headline.contains('あ'), isFalse);
      expect(headline.toMarkup(), markup);
    });
    test('non-ASCII tags', () {
      final markup = '* TODO foo :あ:';
      final result = parser.parse(markup);
      final headline = result.value as OrgHeadline;
      expect(headline.contains('foo'), isTrue);
      expect(headline.contains('お'), isFalse);
      expect(headline.tags!.values, ['あ']);
      expect(headline.toMarkup(), markup);
    });
    group('tag inheritance', () {
      test('children have no tags', () {
        final markup = """
* School exams :school:
** some exam
** another exam""";
        final result = OrgDocument.parse(markup);
        final parentSection = result.sections[0];
        final firstChildSection = parentSection.sections[0];
        final secondChildSection = parentSection.sections[1];
        expect(parentSection.tagsWithInheritance(result), ["school"]);
        expect(parentSection.tags, ["school"]);
        expect(firstChildSection.tagsWithInheritance(result), ["school"]);
        expect(firstChildSection.tags, isEmpty);
        expect(secondChildSection.tagsWithInheritance(result), ["school"]);
        expect(secondChildSection.tags, isEmpty);
        expect(parentSection.toMarkup(), markup);
      });
      test('parent and child have tags', () {
        final markup = """
* School exams :school:
** History exam :history:""";
        final result = OrgDocument.parse(markup);
        final parentSection = result.sections[0];
        final childSection = parentSection.sections[0];
        expect(parentSection.tagsWithInheritance(result), ["school"]);
        expect(parentSection.tags, ["school"]);
        expect(childSection.tagsWithInheritance(result), ["school", "history"]);
        expect(childSection.tags, ["history"]);
        expect(parentSection.toMarkup(), markup);
      });
      test('no tags', () {
        final markup = """
* School exams
** History exam""";
        final result = OrgDocument.parse(markup);
        final parentSection = result.sections[0];
        final childSection = parentSection.sections[0];
        expect(parentSection.tagsWithInheritance(result), isEmpty);
        expect(parentSection.tags, isEmpty);
        expect(childSection.tagsWithInheritance(result), isEmpty);
        expect(childSection.tags, isEmpty);
        expect(parentSection.toMarkup(), markup);
      });
      test('only child tags', () {
        final markup = """
* School exams
** History exam :history:""";
        final result = OrgDocument.parse(markup);
        final parentSection = result.sections[0];
        final childSection = parentSection.sections[0];
        expect(parentSection.tagsWithInheritance(result), isEmpty);
        expect(parentSection.tags, isEmpty);
        expect(childSection.tagsWithInheritance(result), ["history"]);
        expect(childSection.tags, ["history"]);
        expect(parentSection.toMarkup(), markup);
      });
      test('multi level inheritance', () {
        final markup = """
* Heading A :tag1:
**  Heading B :tag2:
*** Heading C :tag3:""";
        final result = OrgDocument.parse(markup);
        final firstSection = result.sections[0];
        final secondSection = firstSection.sections[0];
        final thirdSection = secondSection.sections[0];
        expect(firstSection.tagsWithInheritance(result), ["tag1"]);
        expect(firstSection.tags, ["tag1"]);
        expect(secondSection.tagsWithInheritance(result), ["tag1", "tag2"]);
        expect(secondSection.tags, ["tag2"]);
        expect(
            thirdSection.tagsWithInheritance(result), ["tag1", "tag2", "tag3"]);
        expect(thirdSection.tags, ["tag3"]);
        expect(firstSection.toMarkup(), markup);
      });
    });
  });
}
