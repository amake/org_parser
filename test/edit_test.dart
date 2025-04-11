import 'package:org_parser/org_parser.dart';
import 'package:test/test.dart';

void main() {
  test('edit', () {
    final doc = OrgDocument.parse('''* TODO [#A] foo bar
  1''');
    final zipper = doc.edit();
    final sectionLoc = zipper.goDown();
    expect(sectionLoc.node, isA<OrgSection>());
    final headlineLoc = sectionLoc.goDown();
    expect(headlineLoc.node, isA<OrgHeadline>());
    final contentLoc = headlineLoc.goRight();
    expect(contentLoc.node, isA<OrgContent>());
    final paragraphLoc = contentLoc.goDown();
    expect(paragraphLoc.node, isA<OrgParagraph>());
    final paragraphContentLoc = paragraphLoc.goDown();
    expect(paragraphContentLoc.node, isA<OrgContent>());
    final textLoc = paragraphContentLoc.goDown();
    expect(textLoc.node, isA<OrgPlainText>());
    final edited = textLoc.replace(OrgPlainText('2')).commit();
    expect(edited.toMarkup(), '''* TODO [#A] foo bar
  2''');
  });
  test('find node', () {
    final doc = OrgDocument.parse('''* TODO [#A] foo bar
  *baz*''');
    final found = doc.find<OrgMarkup>((_) => true)!;
    var zipper = doc.editNode(found.node)!;
    zipper = zipper.replace(
        found.node.copyWith(leadingDecoration: '/', trailingDecoration: '/'));
    final edited = zipper.commit();
    expect(edited.toMarkup(), '''* TODO [#A] foo bar
  /baz/''');
  });
  test('find by predicate', () {
    final doc = OrgDocument.parse('''* TODO [#A] foo bar
  *baz*''');
    var zipper = doc.edit().findWhere((node) => node is OrgMarkup)!;
    final found = zipper.node as OrgMarkup;
    zipper = zipper.replace(
        found.copyWith(leadingDecoration: '/', trailingDecoration: '/'));
    final edited = zipper.commit();
    expect(edited.toMarkup(), '''* TODO [#A] foo bar
  /baz/''');
  });
}
