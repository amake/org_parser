import 'package:org_parser/src/file_link/file_link.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('file link', () {
    final parser = orgFileLink;
    group('with scheme', () {
      test('absolute path', () {
        var result = parser.parse('file:/home/dominik/images/jupiter.jpg');
        var link = result.value as OrgFileLink;
        expect(link.scheme, 'file:');
        expect(link.body, '/home/dominik/images/jupiter.jpg');
        expect(link.extra, isNull);
        expect(link.isRelative, isFalse);
        expect(link.isLocal, isFalse);
      });
      test('relative path', () {
        final result = parser.parse('file:papers/last.pdf');
        final link = result.value as OrgFileLink;
        expect(link.scheme, 'file:');
        expect(link.body, 'papers/last.pdf');
        expect(link.extra, isNull);
        expect(link.isRelative, isTrue);
        expect(link.isLocal, isFalse);
      });
    });
    group('with extra', () {
      test('other file', () {
        final result = parser.parse('file:projects.org::some words');
        final link = result.value as OrgFileLink;
        expect(link.scheme, 'file:');
        expect(link.body, 'projects.org');
        expect(link.extra, 'some words');
        expect(link.isRelative, isTrue);
        expect(link.isLocal, isFalse);
      });
      test('local file', () {
        final result = parser.parse('file:::#custom-id');
        final link = result.value as OrgFileLink;
        expect(link.scheme, 'file:');
        expect(link.body, '');
        expect(link.extra, '#custom-id');
        expect(link.isRelative, isTrue);
        expect(link.isLocal, isTrue);
      });
    });
    group('without scheme', () {
      test('absolute path', () {
        final result = parser.parse('/home/dominik/images/jupiter.jpg');
        final link = result.value as OrgFileLink;
        expect(link.scheme, isNull);
        expect(link.body, '/home/dominik/images/jupiter.jpg');
        expect(link.extra, isNull);
        expect(link.isRelative, isFalse);
        expect(link.isLocal, isFalse);
      });
      test('relative path', () {
        final result = parser.parse('./papers/last.pdf');
        final link = result.value as OrgFileLink;
        expect(link.scheme, isNull);
        expect(link.body, './papers/last.pdf');
        expect(link.extra, isNull);
        expect(link.isRelative, isTrue);
        expect(link.isLocal, isFalse);
      });
    });
    group('non-files', () {
      test('https', () {
        final result = parser.parse('https://example.com');
        expect(result, isA<Failure>());
      });
      test('mailto', () {
        final result = parser.parse('mailto:me@example.com');
        expect(result, isA<Failure>());
      });
    });
    test('factory', () {
      final link = OrgFileLink.parse('file:papers/last.pdf');
      expect(link.scheme, 'file:');
      expect(link.body, 'papers/last.pdf');
      expect(link.extra, isNull);
      expect(link.isRelative, isTrue);
      try {
        OrgFileLink.parse('https://example.com');
        fail('OrgFileLink parser should not accept HTTPS link');
      } on ParserException {
        // OK
      }
    });
  });
}
