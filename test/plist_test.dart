import 'package:org_parser/src/plist/model.dart';
import 'package:org_parser/src/plist/parser.dart';
import 'package:test/test.dart';

void main() {
  group('parser', () {
    final parser = PlistParser().build();
    test('symbols', () {
      final result = parser.parse('foo bar baz').value;
      expect(result, ['foo', 'bar', 'baz']);
    });
    test('strings', () {
      final result = parser.parse('"foo bar" baz').value;
      expect(result, ['foo bar', 'baz']);
    });
    test('escaped strings', () {
      final result = parser.parse(r'"foo \"bar\"" baz').value;
      expect(result, ['foo "bar"', 'baz']);
    });
    test('invalid string', () {
      final result = parser.parse(r'"foo bar baz').value;
      expect(result, ['"foo', 'bar', 'baz']);
    });
    test('empty', () {
      final result = parser.parse('').value;
      expect(result, <String>[]);
    });
    test('whitespace', () {
      final result = parser.parse('   foo   bar   ').value;
      expect(result, ['foo', 'bar']);
    });
    test('just whitespace', () {
      final result = parser.parse(' ').value;
      expect(result, <String>[]);
    });
  });
  group('model', () {
    test('get', () {
      final plist = Plist.from(':foo bar baz');
      expect(plist.get(':foo'), 'bar');
      expect(plist.get('foo'), isNull);
      expect(plist.get('bar'), 'baz');
      expect(plist.get('baz'), isNull);
      expect(plist.get('qux'), isNull);
    });
    test('has', () {
      final plist = Plist.from(':foo bar baz');
      expect(plist.has(':foo'), isTrue);
      expect(plist.has('foo'), isFalse);
      expect(plist.has('bar'), isTrue);
      expect(plist.has('baz'), isTrue);
      expect(plist.has('qux'), isFalse);
    });
  });
}
