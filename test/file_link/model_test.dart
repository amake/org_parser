import 'package:org_parser/src/file_link/file_link.dart';
import 'package:test/test.dart';

void main() {
  group('file link', () {
    test('file: relative', () {
      final link = OrgFileLink.parse('file:foo.org');
      expect(link.isLocal, isFalse);
      expect(link.isRelative, isTrue);
      expect(link.scheme, 'file:');
      expect(link.body, 'foo.org');
      expect(link.extra, isNull);
    });
    test('file: local', () {
      final link = OrgFileLink.parse('file:::*');
      expect(link.isLocal, isTrue);
      expect(link.isRelative, isTrue);
      expect(link.scheme, 'file:');
      expect(link.body, '');
      expect(link.extra, '*');
    });
    test('attachment: relative', () {
      final link = OrgFileLink.parse('attachment:foo.org');
      expect(link.isLocal, isFalse);
      expect(link.isRelative, isTrue);
      expect(link.scheme, 'attachment:');
      expect(link.body, 'foo.org');
      expect(link.extra, isNull);
    });
  });
}
