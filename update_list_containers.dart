import 'dart:io';

void main() {
  final dir = Directory('lib/screens/admin');
  final files = dir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      bool changed = false;

      // Replace dividers in ListView.separated
      final dividerRegex = RegExp(r'separatorBuilder:\s*\(_,\s*__\)\s*=>\s*const\s*Divider\(height:\s*1\),');
      if (dividerRegex.hasMatch(content)) {
        content = content.replaceAll(dividerRegex, 'separatorBuilder: (_, __) => const SizedBox(),');
        changed = true;
      }

      // Replace Card elevation
      final cardRegex = RegExp(r'Card\(\s*elevation:\s*\d+,');
      if (cardRegex.hasMatch(content)) {
        content = content.replaceAllMapped(cardRegex, (match) {
          return 'Card(\n  elevation: 20,\n  shadowColor: AppTheme.adminPrimary.withOpacity(0.3),';
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
