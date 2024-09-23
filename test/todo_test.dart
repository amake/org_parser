import 'package:org_parser/org_parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('grammar', () {
    group('components', () {
      final parserDefinition = TodoGrammar();
      Parser buildSpecific(Parser Function() start) {
        return parserDefinition.buildFrom(start()).end();
      }

      group('todoState', () {
        test('without key', () {
          final parser = buildSpecific(parserDefinition.todoState);
          final result = parser.parse('TODO').value;
          expect(result, ['TODO', null]);
        });
        test('with key', () {
          final parser = buildSpecific(parserDefinition.todoState);
          final result = parser.parse('TODO(a)').value;
          expect(result, [
            'TODO',
            ['(', 'a', ')']
          ]);
        });
      });
      group('todoStates', () {
        test('without keys', () {
          final parser = buildSpecific(parserDefinition.todoStates);
          final result = parser.parse('ASIS TOBE').value;
          expect(result, [
            ['ASIS', null],
            ['TOBE', null]
          ]);
        });
        test('with keys', () {
          final parser = buildSpecific(parserDefinition.todoStates);
          final result = parser.parse('ASIS(a) TOBE(b)').value;
          expect(result, [
            [
              'ASIS',
              ['(', 'a', ')'],
            ],
            [
              'TOBE',
              ['(', 'b', ')'],
            ]
          ]);
        });
      });
      group('workflow', () {
        test('without done', () {
          final parser = buildSpecific(parserDefinition.workflow);
          final result = parser.parse('ASIS ASWAS TOBE').value;
          expect(
            result,
            [
              [
                ['ASIS', null],
                ['ASWAS', null],
                ['TOBE', null],
              ],
              null,
            ],
          );
        });
        test('with done', () {
          final parser = buildSpecific(parserDefinition.workflow);
          final result = parser.parse('ASIS ASWAS | TOBE').value;
          expect(
            result,
            [
              [
                ['ASIS', null],
                ['ASWAS', null],
              ],
              [
                ['TOBE', null]
              ]
            ],
          );
        });
        test('without todo', () {
          final parser = buildSpecific(parserDefinition.workflow);
          final result = parser.parse('| ASIS ASWAS TOBE').value;
          expect(
            result,
            [
              null,
              [
                ['ASIS', null],
                ['ASWAS', null],
                ['TOBE', null]
              ]
            ],
          );
        });
        test('with keys', () {
          final parser = buildSpecific(parserDefinition.workflow);
          final result = parser.parse('ASIS(a) ASWAS(b) | TOBE(c)').value;
          expect(
            result,
            [
              [
                [
                  'ASIS',
                  ['(', 'a', ')']
                ],
                [
                  'ASWAS',
                  ['(', 'b', ')']
                ],
              ],
              [
                [
                  'TOBE',
                  ['(', 'c', ')']
                ]
              ]
            ],
          );
        });
      });
    });

    group('full', () {
      final parser = TodoGrammar().build();
      test('manual 1', () {
        final result =
            parser.parse('TODO FEEDBACK VERIFY | DONE CANCELED').value;
        expect(result, [
          [
            ['TODO', null],
            ['FEEDBACK', null],
            ['VERIFY', null],
          ],
          [
            ['DONE', null],
            ['CANCELED', null],
          ],
        ]);
      });
      test('manual 2', () {
        final result = parser.parse('TODO(t) | DONE(d)').value;
        expect(result, [
          [
            [
              'TODO',
              ['(', 't', ')']
            ]
          ],
          [
            [
              'DONE',
              ['(', 'd', ')']
            ]
          ]
        ]);
      });
      test('manual 3', () {
        final result =
            parser.parse('REPORT(r) BUG(b) KNOWNCAUSE(k) | FIXED(f)').value;
        expect(result, [
          [
            [
              'REPORT',
              ['(', 'r', ')']
            ],
            [
              'BUG',
              ['(', 'b', ')']
            ],
            [
              'KNOWNCAUSE',
              ['(', 'k', ')']
            ]
          ],
          [
            [
              'FIXED',
              ['(', 'f', ')']
            ]
          ]
        ]);
      });
      test('manual 4', () {
        final result = parser.parse('| CANCELED(c)').value;
        expect(result, [
          null,
          [
            [
              'CANCELED',
              ['(', 'c', ')']
            ]
          ]
        ]);
      });
      test('manual 5', () {
        final result =
            parser.parse('TODO(t) WAIT(w@/!) | DONE(d!) CANCELED(c@)').value;
        expect(result, [
          [
            [
              'TODO',
              ['(', 't', ')']
            ],
            [
              'WAIT',
              ['(', 'w@/!', ')']
            ]
          ],
          [
            [
              'DONE',
              ['(', 'd!', ')']
            ],
            [
              'CANCELED',
              ['(', 'c@', ')']
            ]
          ]
        ]);
      });
      test('non-ASCII', () {
        final result = parser.parse('あ い').value;
        expect(result, [
          [
            ['あ', null],
            ['い', null]
          ],
          null,
        ]);
      });
      test('seemingly malformed', () {
        final result = parser.parse('foo(').value;
        expect(result, [
          [
            ['foo(', null],
          ],
          null,
        ]);
      });
    });
  });
  group('extract', () {
    test('single implied done no todo', () {
      final doc = OrgDocument.parse('''#+TODO: DONE''');
      final result = extractTodoSettings(doc);
      expect(
        result,
        [
          OrgTodoStates(done: ['DONE'])
        ],
      );
    });
    test('single implied done', () {
      final doc = OrgDocument.parse('''#+TODO: TODO DONE''');
      final result = extractTodoSettings(doc);
      expect(
        result,
        [
          OrgTodoStates(todo: ['TODO'], done: ['DONE'])
        ],
      );
    });
    test('single complex', () {
      final doc =
          OrgDocument.parse('''#+TODO: TODO FEEDBACK VERIFY | DONE CANCELED''');
      final result = extractTodoSettings(doc);
      expect(
        result,
        [
          OrgTodoStates(
            todo: ['TODO', 'FEEDBACK', 'VERIFY'],
            done: ['DONE', 'CANCELED'],
          )
        ],
      );
    });
    test('multiple', () {
      final doc = OrgDocument.parse('''
#+TODO: FOO | BAR
#+TODO: TODO FEEDBACK(b) VERIFY | DONE CANCELED''');
      final result = extractTodoSettings(doc);
      expect(
        result,
        [
          OrgTodoStates(todo: ['FOO'], done: ['BAR']),
          OrgTodoStates(
            todo: ['TODO', 'FEEDBACK', 'VERIFY'],
            done: ['DONE', 'CANCELED'],
          )
        ],
      );
    });
    test('empty', () {
      final doc = OrgDocument.parse('''#+TODO:  ''');
      final result = extractTodoSettings(doc);
      expect(result, [OrgTodoStates()]);
    });
  });
}
