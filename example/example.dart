import 'package:org_parser/org_parser.dart';

void main() {
  // Parse a very simple document
  const docString = '''* TODO [#A] foo bar
baz buzz''';
  final doc = OrgDocument.parse(docString);
  final section = doc.sections[0];
  print(section.headline.keyword?.value);
  final title = section.headline.title!.children[0] as OrgPlainText;
  print(title.content);
  final paragraph = section.content!.children[0] as OrgParagraph;
  final body = paragraph.body.children[0] as OrgPlainText;
  print(body.content);

  // Extract TODOs from a document

  const agendaDoc = '''* TODO Go fishing
** Equipment
- Fishing rod
- Bait
- Hat
* TODO Eat lunch
** Restaurants
- Famous Ray's
- Original Ray's
* TODO Take a nap''';
  final agenda = OrgDocument.parse(agendaDoc);
  agenda.visitSections((section) {
    if (section.headline.keyword?.value == 'TODO') {
      final title = section.headline.title!.children
          .whereType<OrgPlainText>()
          .map((plainText) => plainText.content)
          .join();
      print("I'm going to ${title.toLowerCase()}");
    }
    return true;
  });
}
