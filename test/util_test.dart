import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  test('indent parser', () {
    final parser = whitespace().star() & indentedRegion();
    var result = parser.end().pick(1).parse('''  abc
  def
  hij''');
    expect(result.value, 'abc\n  def\n  hij');
    result = parser.pick(1).parse('''  abc
  def
 hij''');
    expect(result.value, 'abc\n  def\n',
        reason: 'last line has less indentation');
    result = parser.end().pick(1).parse('''  abc
   def
  hij''');
    expect(result.value, 'abc\n   def\n  hij',
        reason: 'more indentation is ok');
    result = parser.end().pick(1).parse('''  abc
  def

  hij''');
    expect(result.value, 'abc\n  def\n\n  hij', reason: 'blank lines are ok');
  });
  test('recursive list parser', () {
    final listStart =
        (lineStart() & whitespace().starString() & string('- ')).flatten();
    final list = undefined<dynamic>();
    list.set(listStart &
        indentedRegion(
            parser: (list | any().plusLazy(listStart | endOfInput()).flatten())
                .star()));
    final result = list.plus().end().parse('''- abc
- def
  - hij''');
    expect(result.value, [
      [
        '- ',
        ['abc\n']
      ],
      [
        '- ',
        [
          'def\n',
          [
            '  - ',
            ['hij']
          ]
        ]
      ]
    ]);
  });
  test('no-op parser', () {
    var parser = noOpFail();
    var result = parser.parse('');
    expect(result is Failure, true);
    parser = NoOpParser(true);
    result = parser.parse('');
    expect(result is Success, true);
    expect(result.value, null);
  });
  test('block parser', () {
    final parser = blockParser();
    var result = parser.parse('''#+begin_foo
   bar
#+end_foo''');
    expect(result.value, [
      'foo',
      ['#+begin_', 'foo', '\n'],
      '   bar\n',
      ['', '#+end_foo']
    ]);
    result = parser.parse('''#+begin_foo
#+end_foo''');
    expect(result.value, [
      'foo',
      ['#+begin_', 'foo', '\n'],
      '',
      ['', '#+end_foo']
    ]);
    result = parser.parse('''#+begin_foo
    #+end_bar''');
    expect(result is Failure, true);
  });
  group('unicode', () {
    test('anyCodePoint', () {
      expect(anyCodePoint().parse('𠮟').value, 0x20B9F);
      expect(anyCodePoint().parse('a').value, 0x61);
      expect(anyCodePoint().parse(''), isA<Failure>());
    });
    test('line-breakable', () {
      // U+2E80–U+312F
      expect(lineBreakable().parse('あ').value, 'あ');
      // U+3190–U+33FF
      expect(lineBreakable().parse('㉀').value, '㉀');
      // U+3400–U+9FFF
      expect(lineBreakable().parse('㑂').value, '㑂');
      // U+F900–U+FAFF
      expect(lineBreakable().parse('豈').value, '豈');
      // U+20000–U+2FFFF
      expect(lineBreakable().parse('𠀡').value, '𠀡');
      // U+30000–U+323AF
      expect(lineBreakable().parse('𱁬').value, '𱁬');
      expect(lineBreakable().parse('༔').value, '༔');
      expect(lineBreakable().parse('༐').value, '༐');
      expect(lineBreakable().parse('a'), isA<Failure>());
      expect(lineBreakable().parse(''), isA<Failure>());
    });
    test('alnum', () {
      expect(alnum().parse('a').value, 0x61);
      expect(alnum().parse('1').value, 0x31);
      expect(alnum().parse('𬶐').value, 0x2CD90);
      expect(alnum().parse('🄊').value, 0x1F10A);
      expect(alnum().parse('.'), isA<Failure>());
      expect(alnum().parse('。'), isA<Failure>());
    });
  });
}
