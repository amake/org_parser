import 'package:functional_zipper/functional_zipper.dart';
import 'package:org_parser/org_parser.dart';

typedef OrgZipper = ZipperLocation<OrgNode, OrgLeafNode, OrgParentNode>;

extension ZipperExt<ZR, ZI extends ZR, ZS extends ZR>
    on ZipperLocation<ZR, ZI, ZS> {
  bool _canGoRight() {
    if (path is TopPath) {
      return false;
    }
    final p = path as NodePath<ZS, ZR>;
    return p.right.isNotEmpty;
  }

  bool _canGoUp() {
    return path is NodePath;
  }

  bool _canGoDown() {
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
  ZipperLocation<ZR, ZI, ZS>? find(ZR node) {
    var location = this;
    while (true) {
      if (identical(location.node, node)) {
        return location;
      }
      if (location._canGoDown()) {
        location = location.goDown();
        continue;
      }
      if (location._canGoRight()) {
        location = location.goRight();
        continue;
      }

      retracing:
      while (true) {
        if (location._canGoUp()) {
          location = location.goUp();
        } else {
          return null;
        }
        if (location._canGoRight()) {
          location = location.goRight();
          break retracing;
        }
      }
    }
  }
}
