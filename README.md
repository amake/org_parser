# org_parser

An [Org Mode](https://orgmode.org/) parser for Dart.

# Usage

For displaying Org Mode documents in Flutter applications, see
[org_flutter](https://github.com/amake/org_flutter). For an example application
that displays Org Mode documents with org_parser and org_flutter, see
[Orgro](https://orgro.org).

This package allows you to parse raw Org Mode documents into a structured
in-memory representation.

```dart
import 'package:org_parser/org_parser.dart';

final doc = OrgDocument.parse('''* TODO [#A] foo bar
baz buzz''');
print(doc.children[0].headline.keyword); // TODO
```

See the [example](./example/example.dart) for more.

# Caveats

This parser was developed for an application that is halfway between
pretty-printing and evaluating/interpreting, so in many cases the parsed
structure does not split out constituent parts as thoroughly as needed for some
applications.

# Supported syntax

- Sections/headlines

    ```org
    * TODO [#A] foo bar
    ```
- Blocks

    ```org
    #+BEGIN_SRC
    foo bar
    #+END_SRC
    ```
- Inline src

    ```org
    foo src_sh{echo "bar"} baz
    ```
- Affiliated keywords

    ```org
    #+name: foo
    ```
- Fixed-width areas

    ```org
    : foo bar
    : baz buzz
    ```
- Tables

    ```org
    | foo | bar |
    |-----+-----|
    | biz | baz |
    ```
- Lists

    ```org
    - foo
      - [X] bar
        1. baz
        2. buzz
    ```
- Drawers

    ```org
    :PROPERTIES:
    foo bar
    :END:
    ```
- Footnotes

    ```org
    Foo bar[fn:1] biz buzz

    [fn:1] Bazinga
    ```
- Links

    ```org
    [[http://example.com][example]]

    http://example.com
    ```
- Emphasis markup

    ```org
    *bold* /italic/ _underline_ +strikethrough+ ~code~ =verbatim=
    ```
- Timestamps

    ```org
    [2020-05-05 Tue]

    <2020-05-05 Tue 10:00>
    ```
- Macro references

    ```org
    {{{kbd(C-c C-c)}}}
    ```

- LaTeX fragments

    ```org
    Then we add $a^2$ to \(b^2\)
    ```

    ```org
    \begin{equation}
    \nabla \times \mathbf{B} = \frac{1}{c}\left( 4\pi\mathbf{J} + \frac{\partial \mathbf{E}}{\partial t}\right)
    \end{equation}
    ```

- Entities

    ```org
    a\leftrightarrow{}b conversion
    ```

- Citations

    ```org
    [cite:@key]
    ```

- Horizontal rules

    ```org
    -----
    ```
- Radio targets

    ```org
    <<<foo>>>
    ```

- Link targets

    ```org
    <<bar>>
    ```
