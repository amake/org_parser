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
    test('test tag inheritance - children have no tags', () {
      final markup = """
* School exams :school:
** some exam
** another exam""";
      final result = OrgDocument.parse(markup);
      final parentSection = result.sections[0];
      final firstChildSection = parentSection.sections[0];
      final secondChildSection = parentSection.sections[1];
      expect(["school"], parentSection.tagsWithInheritance(result));
      expect(["school"], firstChildSection.tagsWithInheritance(result));
      expect(["school"], secondChildSection.tagsWithInheritance(result));
      expect(parentSection.toMarkup(), markup);
    });
    test('test tag inheritance - parent and child have tags', () {
      final markup = """
* School exams :school:
** History exam :history:""";
      final result = OrgDocument.parse(markup);
      final parentSection = result.sections[0];
      final childSection = parentSection.sections[0];
      expect(["school"], parentSection.tagsWithInheritance(result));
      expect(["school", "history"], childSection.tagsWithInheritance(result));
      expect(parentSection.toMarkup(), markup);
    });
    test('test tag inheritance - no tags', () {
      final markup = """
* School exams
** History exam""";
      final result = OrgDocument.parse(markup);
      final parentSection = result.sections[0];
      final childSection = parentSection.sections[0];
      expect(<List<String>>[], parentSection.tagsWithInheritance(result));
      expect(<List<String>>[], childSection.tagsWithInheritance(result));
      expect(parentSection.toMarkup(), markup);
    });
    test('test tag inheritance - only child tags', () {
      final markup = """
* School exams
** History exam :history:""";
      final result = OrgDocument.parse(markup);
      final parentSection = result.sections[0];
      final childSection = parentSection.sections[0];
      expect(<List<String>>[], parentSection.tagsWithInheritance(result));
      expect(["history"], childSection.tagsWithInheritance(result));
      expect(parentSection.toMarkup(), markup);
    });
    test('test tag inheritance - multi level inheritance', () {
      final markup = """
* Heading A :tag1:
**  Heading B :tag2:
*** Heading C :tag3:""";
      final result = OrgDocument.parse(markup);
      final firstSection = result.sections[0];
      final secondSection = firstSection.sections[0];
      final thirdSection = secondSection.sections[0];
      expect(["tag1"], firstSection.tags);
      expect(["tag1", "tag2"], secondSection.tagsWithInheritance(result));
      expect(["tag1", "tag2", "tag3"], thirdSection.tagsWithInheritance(result));
      expect(firstSection.toMarkup(), markup);
    });
  });
}
