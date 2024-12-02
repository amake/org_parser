import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('radio link', () {
    final definition = OrgContentParserDefinition(radioTargets: ['foo', 'bar']);
    final parser = definition.buildFrom(definition.radioLink()).end();
    test('simple', () {
      final markup = 'foo';
      final result = parser.parse(markup);
      final target = result.value as OrgRadioLink;
      expect(target.contains('foo'), isTrue);
      expect(target.contains('あ'), isFalse);
      expect(target.toMarkup(), markup);
    });
    test('found in content', () {
      final doc = OrgDocument.parse('''
<<<foo>>>
foo''', interpretEmbeddedSettings: true);
      final radioLink = doc.find<OrgRadioLink>((_) => true);
      expect(radioLink!.node.content, 'foo');
    });
    test('found in headline', () {
      final doc = OrgDocument.parse('''
* foo
<<<foo>>>''', interpretEmbeddedSettings: true);
      final radioLink = doc.find<OrgRadioLink>((_) => true);
      expect(radioLink!.node.content, 'foo');
    });
  });
}
