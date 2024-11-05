part of '../model.dart';

/// A LaTeX block, like
/// ```
/// \begin{equation}
/// \nabla \cdot \mathbf{B} = 0
/// \end{equation}
/// ```
class OrgLatexBlock extends OrgLeafNode {
  OrgLatexBlock(
    this.environment,
    this.leading,
    this.begin,
    this.content,
    this.end,
    this.trailing,
  );

  /// The LaTeX environment, like `equation`
  final String environment;
  final String leading;
  final String begin;
  final String content;
  final String end;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      begin.contains(pattern) ||
      content.contains(pattern) ||
      end.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgLatexBlock';

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(begin)
      ..write(content)
      ..write(end)
      ..write(trailing);
  }
}

/// An inline LaTeX snippet, like `$E=mc^2$`
class OrgLatexInline extends OrgLeafNode {
  OrgLatexInline(
    this.leadingDecoration,
    this.content,
    this.trailingDecoration,
  );

  final String leadingDecoration;
  final String content;
  final String trailingDecoration;

  @override
  String toString() => 'OrgLatexInline';

  @override
  bool contains(Pattern pattern) =>
      leadingDecoration.contains(pattern) ||
      content.contains(pattern) ||
      trailingDecoration.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leadingDecoration)
      ..write(content)
      ..write(trailingDecoration);
  }
}
