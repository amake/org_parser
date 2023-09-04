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

  ZR commit() {
    var location = this;
    while (location.path is! TopPath) {
      location = location.goUp();
    }
    return location.node as ZR;
  }

  ZipperLocation<ZR, ZI, ZS>? find(ZR node) {
    var location = this;
    while (true) {
      if (identical(location.node, node)) {
        return location;
      }
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
          return null;
        }
        if (location.canGoRight()) {
          location = location.goRight();
          break retracing;
        }
      }
    }
  }
}
