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
      expect(link.toString(), 'file:foo.org');
      expect(link.toString(withExtra: false), 'file:foo.org');
    });
    test('file: local', () {
      final link = OrgFileLink.parse('file:::*');
      expect(link.isLocal, isTrue);
      expect(link.isRelative, isTrue);
      expect(link.scheme, 'file:');
      expect(link.body, '');
      expect(link.extra, '*');
      expect(link.toString(), 'file:::*');
      expect(link.toString(withExtra: false), 'file:');
    });
    test('file: absolute', () {
      final link = OrgFileLink.parse('file:/home/user/foo.org');
      expect(link.isLocal, isFalse);
      expect(link.isRelative, isFalse);
      expect(link.scheme, 'file:');
      expect(link.body, '/home/user/foo.org');
      expect(link.extra, isNull);
      expect(link.toString(), 'file:/home/user/foo.org');
      expect(link.toString(withExtra: false), 'file:/home/user/foo.org');
    });
    test('file: absolute with extra', () {
      final link = OrgFileLink.parse('file:/home/user/foo.org::1234');
      expect(link.isLocal, isFalse);
      expect(link.isRelative, isFalse);
      expect(link.scheme, 'file:');
      expect(link.body, '/home/user/foo.org');
      expect(link.extra, '1234');
      expect(link.toString(), 'file:/home/user/foo.org::1234');
      expect(link.toString(withExtra: false), 'file:/home/user/foo.org');
    });
    test('attachment: relative', () {
      final link = OrgFileLink.parse('attachment:foo.org');
      expect(link.isLocal, isFalse);
      expect(link.isRelative, isTrue);
      expect(link.scheme, 'attachment:');
      expect(link.body, 'foo.org');
      expect(link.extra, isNull);
      expect(link.toString(), 'attachment:foo.org');
      expect(link.toString(withExtra: false), 'attachment:foo.org');
    });
    test('id:', () {
      final link = OrgFileLink.parse('id:CDEB868D-EE4D-4865-9E5D-FC508152564C');
      expect(link.isLocal, isFalse);
      expect(link.isRelative, isTrue);
      expect(link.scheme, 'id:');
      expect(link.body, 'CDEB868D-EE4D-4865-9E5D-FC508152564C');
      expect(link.extra, isNull);
      expect(link.toString(), 'id:CDEB868D-EE4D-4865-9E5D-FC508152564C');
      expect(link.toString(withExtra: false),
          'id:CDEB868D-EE4D-4865-9E5D-FC508152564C');
    });
  });
}
