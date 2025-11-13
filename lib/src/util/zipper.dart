import 'package:functional_zipper/functional_zipper.dart';
import 'package:org_parser/org_parser.dart';

typedef OrgZipper = ZipperLocation<OrgNode, OrgLeafNode, OrgParentNode>;

extension ZipperExt<ZR, ZI extends ZR, ZS extends ZR>
    on ZipperLocation<ZR, ZI, ZS> {
  bool canGoLeft() {
    if (path is TopPath) {
      return false;
    }
    final p = path as NodePath<ZS, ZR>;
    return p.left.isNotEmpty;
  }

  bool canGoRight() {
    if (path is TopPath) {
      return false;
    }
    final p = path as NodePath<ZS, ZR>;
    return p.right.isNotEmpty;
  }

  bool canGoUp() {
    return path is NodePath;
  }

  bool canGoDown() {
    if (!sectionP(node)) {
      return false;
    }
    final t = node as ZS;
    final cs = getChildren(t);
    return cs.isNotEmpty;
  }

  /// Return the root node of this zipper, thereby "applying" any changes made.
  ZR commit() {
    var location = this;
    while (location.path is! TopPath) {
      location = location.goUp();
    }
    return location.node as ZR;
  }

  /// Navigate to the supplied [node], which is presumed to be a child in the
  /// tree of this zipper. Returns null if the node is not found.
  ZipperLocation<ZR, ZI, ZS>? find(ZR node) =>
      findWhere((n) => identical(n, node));

  /// Navigate to the node that satisfies [predicate]. Returns null if no such
  /// node is not found.
  ZipperLocation<ZR, ZI, ZS>? findWhere(bool Function(dynamic) predicate) {
    ZipperLocation<ZR, ZI, ZS>? result;
    visit((location) {
      if (predicate(location.node)) {
        result = location;
        return (false, null);
      }
      return (true, null);
    });
    return result;
  }

  /// Visit all nodes in the tree, starting from this location. The [visitor]
  /// accepts the visited location, and should return a tuple (bool, location?) where:
  /// - The bool indicates whether to continue the traversal
  /// - The location replaces the location supplied to the visitor. This allows
  ///   the visitor to modify the tree during traversal.
  ///
  /// The return value is the last location visited.
  ZipperLocation<ZR, ZI, ZS> visit(
    (bool, ZipperLocation<ZR, ZI, ZS>?) Function(ZipperLocation<ZR, ZI, ZS>)
        visitor,
  ) {
    var location = this;
    while (true) {
      final (cont, newLocation) = visitor(location);
      location = newLocation ?? location;
      if (!cont) return location;

      if (location.canGoDown()) {
        location = location.goDown();
        continue;
      }
      if (location.canGoRight()) {
        location = location.goRight();
        continue;
      }

      retracing:
      while (true) {
        if (location.canGoUp()) {
          location = location.goUp();
        } else {
          // Retraced back to the top. Traversal complete; return the last
          // location
          return location;
        }
        if (location.canGoRight()) {
          location = location.goRight();
          break retracing;
        }
      }
    }
  }
}
