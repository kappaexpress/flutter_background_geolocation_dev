import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  final sourceDir = 'lib';
  final outputDir = 'doc';

  await processDirectory(sourceDir, outputDir);
}

Future<void> processDirectory(String sourceDir, String outputDir) async {
  final directory = Directory(sourceDir);

  // ディレクトリが存在することを確認
  if (!await directory.exists()) {
    print('Error: Directory $sourceDir does not exist');
    return;
  }

  // ディレクトリ内のすべてのエンティティを列挙
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await processDartFile(entity.path, sourceDir, outputDir);
    }
  }
}

Future<void> processDartFile(
    String filePath, String sourceDir, String outputDir) async {
  final file = File(filePath);
  final content = await file.readAsString();

  // ドキュメンテーションコメントを抽出
  final docComments = extractDocComments(content, filePath);

  // 出力ファイルパスの生成
  final relativePath = path.relative(filePath, from: sourceDir);
  final mdFileName = path.basenameWithoutExtension(relativePath) + '.md';
  final mdFilePath =
      path.join(outputDir, path.dirname(relativePath), mdFileName);

  // 出力ディレクトリの作成
  final outputFileDir = Directory(path.dirname(mdFilePath));
  await outputFileDir.create(recursive: true);

  // Markdownファイルの作成
  final outputFile = File(mdFilePath);
  await outputFile.writeAsString(generateMarkdown(docComments, filePath));

  print('Generated documentation: $mdFilePath');
}

List<DocComment> extractDocComments(String sourceCode, String filePath) {
  final List<DocComment> docComments = [];
  final List<String> lines = sourceCode.split('\n');
  List<String> currentComment = [];
  int lineNumber = 0;

  for (String line in lines) {
    lineNumber++;
    final trimmedLine = line.trim();

    if (trimmedLine.startsWith('///')) {
      // ///を除去して、その後の空白もトリム
      String comment = trimmedLine.substring(3).trim();
      currentComment.add(comment);
    } else {
      if (currentComment.isNotEmpty) {
        // コメントの直後の行からクラス名やメソッド名を抽出
        String context = extractContext(trimmedLine);
        docComments.add(DocComment(
          content: currentComment.join('\n'),
          lineNumber: lineNumber - currentComment.length,
          context: context,
        ));
        currentComment = [];
      }
    }
  }

  // ファイル末尾のコメントを処理
  if (currentComment.isNotEmpty) {
    docComments.add(DocComment(
      content: currentComment.join('\n'),
      lineNumber: lineNumber,
      context: '',
    ));
  }

  return docComments;
}

String extractContext(String line) {
  // クラス、メソッド、変数の定義を検出
  line = line.trim();
  if (line.startsWith('class ') ||
      line.startsWith('void ') ||
      line.startsWith('String ') ||
      line.startsWith('int ') ||
      line.startsWith('double ') ||
      line.startsWith('bool ') ||
      line.startsWith('Future<') ||
      line.startsWith('Stream<') ||
      RegExp(r'^[A-Z][a-zA-Z0-9_]*\s').hasMatch(line)) {
    // コメントや中括弧を除去
    line = line.split('//')[0].split('{')[0].trim();
    return line;
  }
  return '';
}

String generateMarkdown(List<DocComment> comments, String filePath) {
  final buffer = StringBuffer();

  buffer.writeln('# ${path.basename(filePath)}');
  buffer.writeln();
  buffer.writeln('Path: `$filePath`');
  buffer.writeln();

  if (comments.isEmpty) {
    buffer.writeln('No documentation comments found.');
    return buffer.toString();
  }

  for (var comment in comments) {
    if (comment.context.isNotEmpty) {
      buffer.writeln('## ${comment.context}');
    }
    buffer.writeln();
    buffer.writeln('Line ${comment.lineNumber}:');
    buffer.writeln();
    buffer.writeln(comment.content);
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  return buffer.toString();
}

class DocComment {
  final String content;
  final int lineNumber;
  final String context;

  DocComment({
    required this.content,
    required this.lineNumber,
    required this.context,
  });
}
