import 'dart:math';

import 'package:org_parser/org_parser.dart';
import 'package:test/test.dart';

void main() {
  group('robustness', () {
    test('OrgDocument.parse does not throw on short punctuation-heavy inputs',
        () {
      const alphabet = [
        '*',
        ' ',
        '\n',
        ':',
        '[',
        ']',
        '#',
        '+',
        '-',
        '/',
        '\\',
        '{',
        '}',
        '<',
        '>',
        '|',
        'a',
        '1',
        '\r',
        '\t',
      ];

      for (var len = 0; len <= 4; len++) {
        final total = pow(alphabet.length, len).toInt();
        for (var i = 0; i < total; i++) {
          var n = i;
          final buf = StringBuffer();
          for (var j = 0; j < len; j++) {
            buf.write(alphabet[n % alphabet.length]);
            n ~/= alphabet.length;
          }
          final input = buf.toString();
          expect(
            () => OrgDocument.parse(input),
            returnsNormally,
            reason: 'input=${_escape(input)}',
          );
        }
      }
    });

    test('OrgDocument.parse does not throw on deterministic randomized inputs',
        () {
      const alphabet = [
        '*',
        ' ',
        '\n',
        ':',
        '[',
        ']',
        '#',
        '+',
        '-',
        '/',
        '\\',
        '{',
        '}',
        '<',
        '>',
        '|',
        'a',
        '1',
        '\r',
        '\t',
      ];
      final rand = Random(0);

      for (var i = 0; i < 5000; i++) {
        final len = rand.nextInt(120);
        final buf = StringBuffer();
        for (var j = 0; j < len; j++) {
          buf.write(alphabet[rand.nextInt(alphabet.length)]);
        }
        final input = buf.toString();
        expect(
          () => OrgDocument.parse(input),
          returnsNormally,
          reason: 'case=$i input=${_escape(input)}',
        );
      }
    });
  });
}

String _escape(String input) => input
    .replaceAll('\\', r'\\')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r')
    .replaceAll('\t', r'\t');
