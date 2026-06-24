import 'dart:io';

void main() {
  final dir = Directory('lib/screens/admin');
  final files = dir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      bool changed = false;

      final editRegex = RegExp(r'const Icon\(Icons\.edit_(.*?),\s*color:\s*(.*?)\)');
      if (editRegex.hasMatch(content)) {
        content = content.replaceAllMapped(editRegex, (match) {
          String suffix = match.group(1)!;
          String color = match.group(2)!;
          return 'Icon(Icons.edit_$suffix, color: $color, shadows: [Shadow(color: $color.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))])';
        });
        changed = true;
      }

      final deleteRegex = RegExp(r'const Icon\(Icons\.delete_(.*?),\s*color:\s*(.*?)\)');
      if (deleteRegex.hasMatch(content)) {
        content = content.replaceAllMapped(deleteRegex, (match) {
          String suffix = match.group(1)!;
          String color = match.group(2)!;
          return 'Icon(Icons.delete_$suffix, color: $color, shadows: [Shadow(color: $color.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))])';
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
