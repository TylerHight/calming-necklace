import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';

class FileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;

  FileOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  }) {
    _createFile();
  }

  void _createFile() {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    } else if (overrideExisting) {
      file.writeAsStringSync('', encoding: encoding);
    }
  }

  @override
  void output(OutputEvent event) {
    final output = event.lines.join('\n') + '\n';
    file.writeAsStringSync(
      output,
      encoding: encoding,
      mode: FileMode.append,
    );
  }
}
