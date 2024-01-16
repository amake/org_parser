// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/file_link/file_link.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

void main() {
  group('file link', () {
    final parser = OrgFileLinkGrammarDefinition().build();
    group('with scheme', () {
      test('absolute', () {
        final result = parser.parse('file:/home/dominik/images/jupiter.jpg');
        expect(
            result.value, ['file:', '/home/dominik/images/jupiter.jpg', null]);
      });
      test('relative', () {
        final result = parser.parse('file:papers/last.pdf');
        expect(result.value, ['file:', 'papers/last.pdf', null]);
      });
      test('remote', () {
        final result = parser.parse('file:/ssh:me@some.where:papers/last.pdf');
        expect(
          result.value,
          ['file:', '/ssh:me@some.where:papers/last.pdf', null],
        );
      });
      test('attachment', () {
        final result = parser.parse('attachment:foo.png');
        expect(
          result.value,
          ['attachment:', 'foo.png', null],
        );
      });
    });
    group('with extra', () {
      test('other file with line number', () {
        final result = parser.parse('file:sometextfile::123');
        expect(result.value, ['file:', 'sometextfile', '123']);
      });
      test('other file with search query', () {
        final result = parser.parse('file:projects.org::some words');
        expect(result.value, ['file:', 'projects.org', 'some words']);
      });
      test('other file with headline', () {
        final result = parser.parse('file:projects.org::*task title');
        expect(result.value, ['file:', 'projects.org', '*task title']);
      });
      test('other file with custom id', () {
        final result = parser.parse('file:projects.org::#custom-id');
        expect(result.value, ['file:', 'projects.org', '#custom-id']);
      });
      test('local file', () {
        final result = parser.parse('file:::*task title');
        expect(result.value, ['file:', '', '*task title']);
      });
    });
    group('without scheme', () {
      test('absolute path', () {
        final result = parser.parse('/home/dominik/images/jupiter.jpg');
        expect(result.value, ['', '/home/dominik/images/jupiter.jpg', null]);
      });
      test('relative path', () {
        final result = parser.parse('./papers/last.pdf');
        expect(result.value, ['', './papers/last.pdf', null]);
      });
      test('sibling with custom ID', () {
        final result = parser.parse('./projects.org::#custom-id');
        expect(result.value, ['', './projects.org', '#custom-id']);
      });
      test('parent with custom ID', () {
        final result = parser.parse('../projects.org::#custom-id');
        expect(result.value, ['', '../projects.org', '#custom-id']);
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
    test('detect common problems', () {
      expect(linter(parser), isEmpty);
    });
  });
}
