import 'dart:io';

void main() {
  final dir = Directory('lib/screens/admin');
  final files = dir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      bool changed = false;

      final regex = RegExp(r'shadows:\s*\[Shadow\(color:\s*(.*?)\.withOpacity\(0\.5\),\s*blurRadius:\s*20,\s*offset:\s*const\s*Offset\(0,\s*5\)\)\]');
      if (regex.hasMatch(content)) {
        content = content.replaceAllMapped(regex, (match) {
          String color = match.group(1)!;
          return 'shadows: [Shadow(color: $color, blurRadius: 10, offset: const Offset(0, 6))]';
        });
        changed = true;
      }

      if (changed) {
        file.writeAsStringSync(content);
        print('Updated: ${file.path}');
      }
    }
  }
}
