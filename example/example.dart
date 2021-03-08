import 'package:org_parser/org_parser.dart';

void main() {
  const docString = '''* TODO [#A] foo bar
baz buzz''';
  final doc = OrgDocument.parse(docString);
  final section = doc.children[0];
  print(section.headline.keyword);
  final title = section.headline.title!.children[0] as OrgPlainText;
  print(title.content);
  final paragraph = section.content!.children[0] as OrgParagraph;
  final body = paragraph.body.children[0] as OrgPlainText;
  print(body.content);
}
