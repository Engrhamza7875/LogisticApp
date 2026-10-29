import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('print(')) {
        var newContent = content.replaceAll(RegExp(r'(?<!//.*)print\('), 'appLogger.i(');
        
        // Add import if not present
        if (!newContent.contains('logger_service.dart')) {
          // Add after existing imports or at top
          final importLine = "import 'package:sabcargo/services/logger_service.dart';\n";
          if (newContent.startsWith('import ')) {
            newContent = importLine + newContent;
          } else {
             newContent = importLine + newContent;
          }
        }
        
        entity.writeAsStringSync(newContent);
        print('Updated: ${entity.path}');
      }
    }
  });
}
