import 'dart:convert';
import 'dart:io';

import 'package:org_parser/org_parser.dart';
// import 'package:petitparser/debug.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

const _htmlTemplate = '''<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
	<link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/spiermar/d3-flame-graph@1.0.4/dist/d3.flameGraph.min.css">
	<style>
    /* Space out content a bit */
    body {
      padding-top: 20px;
      padding-bottom: 20px;
    }
    /* Custom page header */
    .header {
      padding-bottom: 20px;
      padding-right: 15px;
      padding-left: 15px;
      border-bottom: 1px solid #e5e5e5;
    }
    /* Make the masthead heading the same height as the navigation */
    .header h3 {
      margin-top: 0;
      margin-bottom: 0;
      line-height: 40px;
    }
    /* Customize container */
    .container {
      max-width: 990px;
    }
    </style>
    <title>@@NAME@@</title>
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="container">
      <div class="header clearfix">
        <nav>
          <div class="pull-right">
            <form class="form-inline" id="form">
              <a class="btn" href="javascript: resetZoom();">Reset zoom</a>
              <a class="btn" href="javascript: clear();">Clear</a>
              <div class="form-group">
                <input type="text" class="form-control" id="term">
              </div>
              <a class="btn btn-primary" href="javascript: search();">Search</a>
            </form>
          </div>
        </nav>
        <h3 class="text-muted">@@NAME@@</h3>
      </div>
      <div id="chart">
      </div>
      <hr>
      <div id="details">
      </div>
    </div>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/d3/4.10.0/d3.min.js"></script>
  	<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/d3-tip/0.7.1/d3-tip.min.js"></script>
  	<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/spiermar/d3-flame-graph@1.0.4/dist/d3.flameGraph.min.js"></script>
	<script type="text/javascript">
		var data = @@DATA@@;
	</script>
	<script type="text/javascript">
    var flameGraph = d3.flameGraph()
      .width(960)
      .cellHeight(18)
      .transitionDuration(750)
      .transitionEase(d3.easeCubic)
      .sort(true)
      .title("")
      .onClick(onClick);
    // Example on how to use custom tooltips using d3-tip.
    var tip = d3.tip()
      .direction("s")
      .offset([8, 0])
      .attr('class', 'd3-flame-graph-tip')
      .html(function(d) { return "name: " + d.data.name + ", value: " + d.data.value; });
    flameGraph.tooltip(tip);
    d3.select("#chart")
      .datum(data)
      .call(flameGraph);
    document.getElementById("form").addEventListener("submit", function(event){
      event.preventDefault();
      search();
    });
    function search() {
      var term = document.getElementById("term").value;
      flameGraph.search(term);
    }
    function clear() {
      document.getElementById('term').value = '';
      flameGraph.clear();
    }
    function resetZoom() {
      flameGraph.resetZoom();
    }
    function onClick(d) {
      console.info("Clicked on " + d.data.name);
    }
    </script>
  </body>
</html>''';

class Frame {
  Frame(this.name);
  String name;
  int _begin;
  int _end;
  final List<Frame> children = [];

  void start() => _begin = DateTime.now().millisecondsSinceEpoch;
  void stop() => _end = DateTime.now().millisecondsSinceEpoch;

  Map<String, Object> get asMap => {
        'name': name,
        'value': _end - _begin,
        'children': children.map((child) => child.asMap).toList(growable: false)
      };
}

class Tracer {
  final List<Frame> stack = [Frame('root')];

  void push(Parser parser) {
    final frame = Frame(parser.runtimeType.toString())..start();
    stack.last.children.add(frame);
    stack.add(frame);
  }

  void pop(Object result) {
    stack.removeLast()
      ..stop()
      ..name += ' $result';
  }

  Frame get _root => stack.first;
  Frame get result {
    assert(_root.children.length == 1);
    return _root.children.first;
  }
}

// Adapted from PetitParser's trace.dart
Parser trace(Parser parser, Tracer tracer) {
  return transformParser(parser, (each) {
    return ContinuationParser(each, (continuation, context) {
      tracer.push(each);
      final result = continuation(context);
      tracer.pop(result);
      return result;
    });
  });
}

void main() {
  group('flame graph', () {
    test('simple document', () {
      const doc = '''An introduction.

* A Headline

  Some text. *bold*

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''';
      final html = flameGraph(OrgParser(), doc);
      File('tmp/profile.html')
        ..parent.createSync()
        ..writeAsStringSync(html);
    });
    test(
      'org-manual',
      () {
        final html = flameGraph(
            OrgGrammar(), File('test/org-manual.org').readAsStringSync());
        File('tmp/org-manual-profile.html')
          ..parent.createSync()
          ..writeAsStringSync(html);
      },
      skip: true,
    );
  });
}

String flameGraph(
  Parser parser,
  String input, {
  String title = 'Org Parser',
}) {
  final tracer = Tracer();
  trace(parser, tracer).parse(input);
  final map = tracer.result.asMap;
  final json = jsonEncode(map);
  return _htmlTemplate
      .replaceAll('@@NAME@@', title)
      .replaceAll('@@DATA@@', json);
}
