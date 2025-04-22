## [9.7.2]
- Fix handling of single-character drawer property values

## [9.7.1]
- Fix behavior of `OrgSrcBlock.fromChildren`

## [9.7.0]
- Add `OrgZipper.findWhere` to allow editing a node by arbitrary predicate

## [9.6.0]
- "Greater" `OrgBlock`s and `OrgDynamicBlock`s can now contain "elements", not
  just rich inline markup

## [9.5.0]
- Expose `orgId` generator for generating `OrgParentNode` IDs
- Allow adding a checkbox to a non-checkbox list item in
  `OrgListItem.toggleCheckbox` (see the `add` argument)
- Fixes to aid structured editing scenarios

## [9.4.0]
- Expose `canGo*` methods on OrgZipper, add `canGoLeft`

## [9.3.0]
- Improve AST for Org planning keywords (see
  [#18](https://github.com/amake/org_parser/issues/18))

## [9.2.0]
- Block type is now exposed as `OrgBlock.type`
- Block content parsing now better matches Org Mode in Emacs
- Dynamic blocks are now parsed as `OrgDynamicBlock`

## [9.1.0]
- `OrgTree.attachDir` now returns a record indicating the type in addition to
  the value

## [9.0.1]
- Fix detection of empty (disabled) TODO settings

## [9.0.0]
- Keyword values are now parsed separately; see `key` and `value` on `OrgMeta`
  - Note that `OrgMeta.trailing` is still present but is guaranteed to only be
    whitespace
- Keyword values are rich content

## [8.4.0]
- Support inline src blocks

## [8.3.1]
- Support min/max-style timestamp repeaters

## [8.3.0]
- Drawer property values can now contain nested rich content

## [8.2.1]
- Drawer parsing accuracy is improved

## [8.2.0]
- Footnote, horizontal rule parsing accuracy is improved
- Trailing blank lines are handled more consistently

## [8.1.1]
- Verbatim and code markups no longer have nested rich content

## [8.1.0]
- Links can now contain nested rich content (except for other links)
- Org "elements" now consistently inherit `OrgElement`
- `OrgFootnote` content can now contain elements

## [8.0.0]
- Markups (bold, italic, etc.) and sub/superscripts can now contain nested rich
  content
- List items containing blocks and drawers are parsed more accurately
- Drawer parsing accuracy is improved

## [7.2.0]
- Parse `<<link targtes>>` and `<<<radio targets>>>`
- Parse links to radio targets. This requires a second parsing pass; see the
  `interpretEmbeddedSettings` arg to `OrgDocument.parse`.
- Improve Unicode handling

## [7.1.2]
- Fix bugs in `OrgNode.contains`

## [7.1.1]
- Minor optimization

## [7.1.0]
- Parse horizontal rules to `OrgHorizontalRule`

## [7.0.1]
- Fix parsing of diary timestamps

## [7.0.0]
- Replace `OrgTimestamp` with specialized classes
  - `OrgDiaryTimestamp`, `OrgSimpleTimestamp`, `OrgTimeRangeTimestamp`,
    `OrgDateRangeTimestamp`
- Introduce `OrgSubSuperscript` sealed parent class

## [6.6.0]
- Introduce `OrgStatisticsCookie` parent class
- Add `OrgStatisticsCookie.update` method
- Fix identifying numerical table cells

## [6.5.0]
- Parse statistics cookies
- Minor optimizations

## [6.4.3]
- Upgrade dependencies

## [6.4.2]
- `OrgParagraph`s are now split on blank lines like in Emacs

## [6.4.1]
- Minor optimization

## [6.4.0]
- Support entities in subscripts and superscripts

## [6.3.0]
- Support non-ASCII headline tags

## [6.2.2]
- Fix lower bound of more dependency

## [6.2.1]
- Restore compatibility with Flutter 3.24

## [6.2.0]
- Parse subscripts and superscripts

## [6.1.1]
- Allow `OrgMeta` nodes to be recognized inside text runs

## [6.1.0]
- Parse Org Cite citations

## [6.0.0]
- Add `orgTodo` parser and `OrgTodoStates` model
- `OrgHeadline.keyword.done` now indicates whether a keyword is considered
  "in-progress" or "done"
- Add `interpretEmbeddedSettings` arg to `OrgDocument.parse`. Pass `true` to
  allow detecting TODO keywords from `#+TODO:` (and related) meta lines.
- `OrgParserDefinition` and `OrgGrammarDefinition` constructors now take a list
  of `OrgTodoStates` rather than string lists

## [5.7.0]
- Introduce `OrgSerializer`: supply a subclass to `OrgNode.toMarkup` to
  customize how a tree is serialized.
- Add `OrgSection.tags`
- Add optional `where` predicate to `OrgTree.findContainingTree`

## [5.6.1]
* Bug fixes

## [5.6.0]
* Add parser, AST for the Org query language described in the [Matching tags and
  properties](https://orgmode.org/manual/Matching-tags-and-properties.html)
  section of the Org manual
* Make `OrgTree.getProperties` public
* Reorganize code

## [5.5.0]
* Adjust `OrgDecryptedContent` to allow serializing to encrypted form
  * Supply an appropriate `DecryptedContentSerializer`
  * See `OrgDecryptedContent.toCleartextMarkup` to obtain the unencrypted form

## [5.4.0]
* Parse PGP encrypted blocks, add representation for decrypted content
* Parse comment lines
* Fix some editing bugs
* Remove `OrgTree.level` (`OrgSection.level` remains)

## [5.3.0]
* Support the `attachment:` protocol in `OrgFileLink`
* `ids`, `customIds` is now on `OrgTree` rather than `OrgSection`
* Added `OrgTree.dirs` to get the `:DIR:` property values of the tree
* Added `OrgTree.attachDir` to get the attachment directory for the tree
* The `OrgPath` returned by `OrgNode.find` now includes the starting node as the
  first item
* Added `OrgFileLink.copyWith`

## [5.2.0]
* Parse Emacs [local variables
  lists](https://www.gnu.org/software/emacs/manual/html_node/emacs/Specifying-File-Variables.html)
  to `OrgLocalVariables` AST node. The content, stripped of prefixes and
  suffixes, is available from `OrgLocalVariables.contentString`.

## [5.1.0]

* Add `OrgNode.find` method for searching for a particular node and its "path"
  in the document
* Change `OrgFootnoteReference` properties
* Add `OrgFootnoteReference.isDefinition` to indicate whether reference is part
  of a footnote definition or merely a reference

## [5.0.0]

* Full support for dumping AST back to Org markup: `OrgNode.toMarkup`
  * Errors in round-tripping are now considered bugs
* Various changes in AST class properties to better support dumping to markup
* While the AST remains immutable, editing operations are now possible via
  [zipper](https://en.wikipedia.org/wiki/Zipper_(data_structure)); see
  `OrgTree.edit` and `OrgTree.editNode`, as well as
  [example.dart](./example/example.dart)
* Simple editing convenience methods added:
  * `OrgListItem.toggleCheckbox`
  * `OrgHeadline.cycleTodo`

## [4.1.1]

* Fix support for inline markup in header titles

## [4.1.0]

* Support "greater" blocks with arbitrary names such as `#+begin_foo`
* Add initial support for dumping AST back to Org markup: `OrgNode.toMarkup`

## [4.0.0]

* Update to petitparser 6.0.1
* Require Dart 3.0 or higher

## [3.1.1]

* Fix parsing of section title text in some cases
  ([#13](https://github.com/amake/org_parser/issues/13))

## [3.1.0]

* Update to petitparser 5.4.0

## [3.0.0]

* Require petitparser 5.1.0 or higher
* Require Dart 2.18 or higher

## [2.2.1]

* Add dartdoc comments to AST, grammar, and parser objects
* Fix incorrect parsing of star-only headlines
  ([#5](https://github.com/amake/org_parser/issues/5))

## [2.2.0]

* Add utilities for recognizing, parsing `id:` and `#custom-id` URLs
  * `isOrgIdUrl` & `parseOrgIdUrl`
  * `isOrgCustomIdUrl` & `parseOrgCustomIdUrl`
* Add `OrgDrawer.properties` for obtaining drawer properties
* Add methods for getting the `ID` and `CUSTOM_ID` properties of a section
  * `OrgSection.ids`
  * `OrgSection.customIds`
* Add `OrgTree.visitSections` for efficiently walking just sections
* `OrgFileLink` now correctly recognizes links with empty file parts like
  `file:::*Section name`, which point to local sections; see
  `OrgFileLink.isLocal`.

## [2.1.1]
* Require petitparser 4.1.0 or higher

## [2.1.0]
* Relicense under the MIT License
* "Plain" links of all built-in types are now recognized (not just http(s): and
  mailto:)
* Added parser, AST for file links; see `OrgFileLink` class, `orgFileLink`
  variable
* Removed the following classes; use noted replacements
  * `OrgGrammar` → `OrgGrammarDefinition().build()`
  * `OrgContentGrammar` → `OrgContentGrammarDefinition().build()`
  * `OrgParser` → `org` variable
  * `OrgContentParser` → `OrgContentParserDefinition().build()`

## [2.0.0]

* Change class hierarchy of AST classes
  * All classes now inherit from `OrgNode`
  * All `OrgNode`s have a `children` property
  * `OrgTree.children` (sections only) is now `OrgTree.sections`
* Easily walk an AST with `OrgNode.visit`

## [1.0.1]

* Fix nullability errors in headline, src block

## [1.0.0]

* Migrate to non-nullable by default

## [0.5.0] - 2021-12-16

* Fix parsing of non-property drawer content
* Parse planning/clock lines as separate elements
  ([#2](https://github.com/amake/org_parser/issues/2))

## [0.4.1] - 2020-08-29

* Fix inline style markup (`*foo*`, `+bar+`, etc.) to span at most one line
  break

## [0.4.0] - 2020-07-21

* Parse entities (`\frac12` → ½, etc.)

## [0.3.2] - 2020-07-18

* More accurate tag handling in section headlines

## [0.3.1] - 2020-07-18

* Fix section headline parsing error

## [0.3.0] - 2020-07-14

* Parse inline and block LaTeX fragments
  ([#1](https://github.com/amake/org_parser/issues/1))

## [0.2.0] - 2020-06-20

* Parse src blocks (`#+begin_src`) as `OrgSrcBlock`; language of block is
  exposed as `OrgSrcBlock.language`

## [0.1.1+1] - 2020-05-21

* Add example

## [0.1.1] - 2020-05-06

* Added `OrgTable.columnIsNumeric` API for determining if a table column is
  primarily comprised of numbers

## [0.1.0] - 2020-05-05

* Initial release
