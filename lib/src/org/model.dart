import 'dart:math';

import 'package:functional_zipper/functional_zipper.dart';
import 'package:org_parser/org_parser.dart';

part 'model/org_block.dart';
part 'model/org_citation.dart';
part 'model/org_comment.dart';
part 'model/org_content.dart';
part 'model/org_decrypted_content.dart';
part 'model/org_drawer.dart';
part 'model/org_dynamic_block.dart';
part 'model/org_entity.dart';
part 'model/org_fixed_width_area.dart';
part 'model/org_footnote.dart';
part 'model/org_headline.dart';
part 'model/org_horizontal_rule.dart';
part 'model/org_latex.dart';
part 'model/org_link.dart';
part 'model/org_link_target.dart';
part 'model/org_list.dart';
part 'model/org_local_variables.dart';
part 'model/org_macro_reference.dart';
part 'model/org_markup.dart';
part 'model/org_meta.dart';
part 'model/org_paragraph.dart';
part 'model/org_pgp_block.dart';
part 'model/org_plain_text.dart';
part 'model/org_planning_entry.dart';
part 'model/org_radio_target.dart';
part 'model/org_section.dart';
part 'model/org_statistics_cookie.dart';
part 'model/org_sub_superscript.dart';
part 'model/org_table.dart';
part 'model/org_timestamp.dart';
part 'model/org_tree.dart';

typedef OrgPath = List<OrgNode>;

/// A class for serializing Org AST objects to Org Mode markup. Subclass and
/// supply to [OrgNode.toMarkup] to customize serialization.
class OrgSerializer {
  final _buf = StringBuffer();

  int get length => _buf.length;

  void visit(OrgNode node) => node._toMarkupImpl(this);

  void write(String str) => _buf.write(str);

  @override
  String toString() => _buf.toString();
}

/// The base type of all Org AST objects
abstract class OrgNode {
  /// The children of this node. May be empty (no children) or null (an object
  /// that can't have children).
  List<OrgNode>? get children;

  /// Return true if this node or any of its children recursively match the
  /// supplied [pattern]
  bool contains(Pattern pattern);

  /// Walk AST with [visitor]. Specify a type [T] to only visit nodes of that
  /// type. The visitor function must return `true` to continue iterating, or
  /// `false` to stop.
  bool visit<T extends OrgNode>(bool Function(T) visitor) {
    final self = this;
    if (self is T) {
      if (!visitor.call(self)) {
        return false;
      }
    }
    final children = this.children;
    if (children != null) {
      for (final child in children) {
        if (!child.visit<T>(visitor)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Find the first node in the AST that satisfies [predicate]. Specify a type
  /// [T] to only visit nodes of that type. Returns a tuple of the node and its
  /// path from the root of the tree, or null if no node is found.
  ({T node, OrgPath path})? find<T extends OrgNode>(
    bool Function(T) predicate, [
    OrgPath path = const [],
  ]) {
    final self = this;
    if (path.isEmpty) {
      path = [self];
    }
    if (self is T && predicate(self)) {
      return (node: self, path: path);
    }
    final children = this.children;
    if (children != null) {
      for (final child in children) {
        final result = child.find<T>(predicate, [...path, child]);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  String toMarkup({OrgSerializer? serializer}) {
    serializer ??= OrgSerializer();
    serializer.visit(this);
    return serializer.toString();
  }

  void _toMarkupImpl(OrgSerializer buf);
}

sealed class OrgLeafNode extends OrgNode {
  @override
  List<OrgNode>? get children => null;
}

enum OrgAttachDirType {
  /// The Org Attach directory is specified by a `:DIR:` property in the
  /// section. Such a directory is relative to the parent file.
  dir,

  /// The Org Attach directory is specified by an `:ID:` property in the
  /// section. Such a directory is relative to `org-attach-id-dir` (default:
  /// `data`).
  id
}

/// Generate a random ID for an Org node. Use this when creating a new node
/// based on an existing node with `copyWith`, where both nodes will be present
/// in the tree at the same time.
String orgId() => Random().nextInt(pow(2, 32).toInt()).toString();

sealed class OrgParentNode extends OrgNode {
  OrgParentNode([String? id]) : id = id ?? orgId();

  /// A unique ID for this node. Use this to identify nodes across edits via
  /// [OrgTree.edit], because [OrgParentNode]s can be recreated and thus will
  /// not be equal via [identical].
  final String id;

  @override
  List<OrgNode> get children;

  OrgParentNode fromChildren(List<OrgNode> children);
}

/// A node potentially containing [OrgSection]s
sealed class OrgTree extends OrgParentNode {
  OrgTree(this.content, [Iterable<OrgSection>? sections, super.id])
      : sections = List.unmodifiable(sections ?? const <OrgSection>[]);

  /// Leading content
  final OrgContent? content;

  /// Sections contained within this tree. These are also iterated by [children].
  final List<OrgSection> sections;

  /// Leading content, if present, followed by [sections]
  @override
  List<OrgNode> get children => [if (content != null) content!, ...sections];

  /// Walk only section nodes of the AST with [visitor]. More efficient than
  /// calling [visit]. The visitor function must return `true` to continue
  /// iterating, or `false` to stop.
  bool visitSections(bool Function(OrgSection) visitor) {
    final self = this;
    if (self is OrgSection && !visitor(self)) {
      return false;
    }
    for (final section in sections) {
      if (!section.visitSections(visitor)) {
        return false;
      }
    }
    return true;
  }

  /// Obtain a zipper starting at the root of this tree. The zipper can be used
  /// to edit the tree; call [ZipperLocation.commit] to obtain a new tree with
  /// the edits applied.
  OrgZipper edit() => ZipperLocation.root(
        sectionP: (obj) => obj is OrgParentNode,
        node: this,
        getChildren: (obj) => obj.children,
        makeSection: (node, children) => node.fromChildren(children),
      );

  /// Obtain a zipper for the specified [node], which is presumed to be in this
  /// tree. Returns null if the node is not found. The zipper can be used to
  /// edit the tree; call [ZipperLocation.commit] to obtain a new tree with the
  /// edits applied.
  OrgZipper? editNode(OrgNode node) => edit().find(node);

  /// Get the ID properties from this section's PROPERTIES drawer, if any.
  List<String> get ids => getProperties(':ID:');

  /// Get the CUSTOM_ID properties from this section's PROPERTIES drawer, if
  /// any.
  List<String> get customIds => getProperties(':CUSTOM_ID:');

  /// Get the DIR properties from this section's PROPERTIES drawer, if any.
  List<String> get dirs => getProperties(':DIR:');

  /// Get the properties corresponding to [key] from this section's PROPERTIES
  /// drawer, if any.
  List<String> getProperties(String key) =>
      _propertiesDrawer
          ?.properties(key: key)
          .map<String>((prop) => prop.value.toMarkup().trim())
          .toList(growable: false) ??
      const [];

  /// Retrieve this section's PROPERTIES drawer, if it exists.
  OrgDrawer? get _propertiesDrawer {
    OrgDrawer? result;
    // Visit [content], not [this], because we don't want to find a drawer in a
    // child section
    content?.visit<OrgDrawer>((drawer) {
      if (drawer.header.trim().toUpperCase() == ':PROPERTIES:') {
        result = drawer;
        // Only first drawer is recognized
        return false;
      }
      return true;
    });
    return result;
  }

  /// Find the immediate parent [OrgSection] or [OrgDocument] of the specified
  /// [node].
  OrgTree? findContainingTree<T extends OrgNode>(T node,
      {bool Function(OrgTree)? where}) {
    where ??= (_) => true;
    final found = find<T>((n) => identical(node, n));
    if (found == null) return null;
    final (node: _, :path) = found;
    for (final node in path.reversed) {
      if (node is OrgTree && where(node)) return node;
    }
    return null;
  }

  /// Get the directory in which attachments are expected to be found for this
  /// section. The behavior follows Org Mode defaults:
  /// `org-attach-use-inheritance` is `selective` and
  /// `org-use-property-inheritance` is `nil`, meaning that the relevant
  /// properties are not inherited from parent sections.
  ///
  /// If the returned type is [OrgAttachDirType.dir], the directory is relative
  /// to the parent file. If the returned type is [OrgAttachDirType.id], the
  /// directory is relative to the attachment directory
  /// (`org-attach-id-dir`).
  ({OrgAttachDirType type, String dir})? get attachDir {
    final dir = dirs.lastOrNull;
    if (dir != null) return (type: OrgAttachDirType.dir, dir: dir);
    final id = ids.lastOrNull;
    if (id != null && id.length >= 3) {
      return (
        type: OrgAttachDirType.id,
        dir: '${id.substring(0, 2)}/${id.substring(2)}'
      );
    }
    return null;
  }

  @override
  bool contains(Pattern pattern, {bool includeChildren = true}) {
    final content = this.content;
    if (content != null && content.contains(pattern)) {
      return true;
    }
    return includeChildren && children.any((child) => child.contains(pattern));
  }

  @override
  String toString() => runtimeType.toString();

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    for (final child in children) {
      buf.visit(child);
    }
  }
}

mixin SingleContentElement {
  String get content;

  bool contains(Pattern pattern) => content.contains(pattern);

  // FIXME(aaron): This appears to be a false positive
  // ignore: unused_element
  void _toMarkupImpl(OrgSerializer buf) {
    buf.write(content);
  }
}

mixin OrgElement {
  /// Indenting whitespace
  String get indent;

  /// Trailing whitespace
  String get trailing;
}
