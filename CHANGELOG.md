## [1.0.0-nullsafety.0]

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
