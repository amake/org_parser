import 'package:org_parser/src/org.dart';
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
  test('indent parser with max blank lines', () {
    final parser =
        whitespace().star() & indentedRegion(maxSeparatingLineBreaks: 1);
    final result = parser.pick(1).parse('''  abc
  def

  hij''');
    expect(result.value, 'abc\n  def\n', reason: 'blank lines are ok');
  });
  test('indent parser with adjustment', () {
    final parser = whitespace().star() & indentedRegion(indentAdjust: 1);
    var result = parser.end().pick(1).parse('''  abc
   def
   hij''');
    expect(result.value, 'abc\n   def\n   hij');
    result = parser.pick(1).parse('''  abc
 def
 hij''');
    expect(result.value, 'abc\n',
        reason: '1 extra space of indentation required');
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
  test('local section url parser', () {
    expect(true, isOrgLocalSectionUrl('*foo'));
    expect(false, isOrgLocalSectionUrl('foo'));
    expect('foo bar', parseOrgLocalSectionUrl('*foo bar'));
    expect('foo bar', parseOrgLocalSectionUrl('''*foo
  bar'''));
  });
  test('custom ID url parser', () {
    expect(true, isOrgCustomIdUrl('#foo'));
    expect(false, isOrgCustomIdUrl('foo'));
    expect('foo bar', parseOrgCustomIdUrl('#foo bar'));
  });
  test('ID url parser', () {
    expect(true, isOrgIdUrl('id:foo'));
    expect(false, isOrgIdUrl('foo'));
    expect('foo bar', parseOrgIdUrl('id:foo bar'));
  });
  test('block parser', () {
    final parser = blockParser();
    var result = parser.parse('''#+begin_foo
   bar
#+end_foo''');
    expect(result.value, [
      ['#+begin_', 'foo', '\n'],
      '   bar\n',
      ['', '#+end_foo']
    ]);
    result = parser.parse('''#+begin_foo
#+end_foo''');
    expect(result.value, [
      ['#+begin_', 'foo', '\n'],
      '',
      ['', '#+end_foo']
    ]);
    result = parser.parse('''#+begin_foo
    #+end_bar''');
    expect(result is Failure, true);
  });
}
