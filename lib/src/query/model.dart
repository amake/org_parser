import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/query/parser.dart';

/// A matcher for displaying the document as a "sparse tree" as in
/// `org-match-sparse-tree`
abstract class OrgQueryMatcher {
  /// Parse a matcher from a query string
  factory OrgQueryMatcher.fromMarkup(String markup) =>
      orgQuery.parse(markup).value as OrgQueryMatcher;

  const OrgQueryMatcher();

  bool matches(OrgSection section);
}

class OrgQueryTagMatcher extends OrgQueryMatcher {
  const OrgQueryTagMatcher(this.tag);

  final String tag;

  @override
  bool matches(OrgSection section) =>
      section.headline.tags?.values.contains(tag) ?? false;

  @override
  bool operator ==(Object other) =>
      other is OrgQueryTagMatcher && other.tag == tag;

  @override
  int get hashCode => tag.hashCode;

  @override
  String toString() => 'OrgQueryTagMatcher[$tag]';
}

class OrgQueryPropertyMatcher extends OrgQueryMatcher {
  const OrgQueryPropertyMatcher({
    required this.property,
    required this.operator,
    required this.value,
  });

  final String property;
  final String operator;
  final dynamic value;

  @override
  bool matches(OrgSection section) {
    final value = this.value;
    switch (property) {
      case 'TODO':
        return value is String &&
            evaluateString(section.headline.keyword?.value, operator, value);
      case 'LEVEL':
        return value is num && evaluateNumber(section.level, operator, value);
      case 'PRIORITY':
        return value is String &&
            evaluateString(
              // The default priority is "B"
              // TODO(aaron): This knowledge shouldn't live here
              // TODO(aaron): Support custom priorities, numeric priorities
              section.headline.priority?.value ?? 'B',
              operator,
              value,
            );
      default:
        final actual = section.getProperties(property).firstOrNull;
        if (value is String) {
          return evaluateString(actual, operator, value);
        } else if (actual != null && value is num) {
          return evaluateNumber(num.parse(actual), operator, value);
        }
    }
    throw UnimplementedError();
  }

  bool evaluateString(String? left, String operator, String right) {
    switch (operator) {
      case '=' || '==':
        return left == right;
      case '<>' || '!=':
        return left != right;
      case '>':
        // Should be consistent with `org-string>`
        return left == null || left.compareTo(right) > 0;
      case '=>' || '>=':
        // Should be consistent with `org-string>=`
        return left == null || left.compareTo(right) >= 0;
      case '<':
        // Should be consistent with `org-string<`
        return left != null && left.compareTo(right) < 0;
      case '=<' || '<=':
        // Should be consistent with `org-string<=`
        return left != null && left.compareTo(right) <= 0;
    }
    throw UnimplementedError();
  }

  bool evaluateNumber(num? left, String operator, num right) {
    switch (operator) {
      case '=' || '==':
        return left == right;
      case '<>' || '!=':
        return left != right;
      case '>':
        return left == null || left > right;
      case '=>' || '>=':
        return left == null || left >= right;
      case '<':
        return left != null && left < right;
      case '=<' || '<=':
        return left != null && left <= right;
    }
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      other is OrgQueryPropertyMatcher &&
      other.property == property &&
      other.operator == operator &&
      other.value == value;

  @override
  int get hashCode => Object.hash(property, operator, value);

  @override
  String toString() => 'OrgQueryPropertyMatcher[$property$operator$value]';
}

class OrgQueryNotMatcher extends OrgQueryMatcher {
  const OrgQueryNotMatcher(this.child);

  final OrgQueryMatcher child;

  @override
  bool matches(OrgSection section) => !child.matches(section);

  @override
  bool operator ==(Object other) =>
      other is OrgQueryNotMatcher && other.child == child;

  @override
  int get hashCode => child.hashCode;

  @override
  String toString() => 'OrgQueryNotMatcher[$child]';
}

class OrgQueryAndMatcher extends OrgQueryMatcher {
  OrgQueryAndMatcher(Iterable<OrgQueryMatcher> children)
      : children = List.unmodifiable(children);

  final List<OrgQueryMatcher> children;

  @override
  bool matches(OrgSection section) =>
      children.every((selector) => selector.matches(section));

  @override
  bool operator ==(Object other) {
    if (other is! OrgQueryAndMatcher) return false;
    if (other.children.length != children.length) return false;
    for (var i = 0; i < children.length; i++) {
      if (children[i] != other.children[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(children);

  @override
  String toString() => 'OrgQueryAndMatcher[${children.join('&')}]';
}

class OrgQueryOrMatcher extends OrgQueryMatcher {
  OrgQueryOrMatcher(Iterable<OrgQueryMatcher> children)
      : children = List.unmodifiable(children);

  final List<OrgQueryMatcher> children;

  @override
  bool matches(OrgSection section) =>
      children.any((selector) => selector.matches(section));

  @override
  bool operator ==(Object other) {
    if (other is! OrgQueryOrMatcher) return false;
    if (other.children.length != children.length) return false;
    for (var i = 0; i < children.length; i++) {
      if (children[i] != other.children[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(children);

  @override
  String toString() => 'OrgQueryOrMatcher[${children.join('|')}]';
}
