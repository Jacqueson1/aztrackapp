import 'dart:io';

void main() {
  final dir = Directory('lib/screens/admin');
  final files = dir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      if (content.contains('AppTheme.slateBlue') || content.contains('AppTheme.navy')) {
        content = content.replaceAll('AppTheme.slateBlue', 'AppTheme.adminPrimary');
        content = content.replaceAll('AppTheme.navy', 'AppTheme.adminText');
        file.writeAsStringSync(content);
        print('Updated: ${file.path}');
      }
    }
  }
}
