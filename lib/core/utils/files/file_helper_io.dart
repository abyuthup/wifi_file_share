import 'dart:io';
import 'package:cross_file/cross_file.dart';
import '../../../features/home/domain/entities/shared_file.dart';
import '../platform_utils.dart';

class FileHelper {
  Future<List<SharedFile>> processFiles(List<XFile> files) async {
    final newFiles = <SharedFile>[];

    for (final file in files) {
      final f = File(file.path);
      if (FileSystemEntity.isDirectorySync(f.path)) {
        // Recursive add
        final dir = Directory(f.path);
        // Use synchronous recursive listing or async stream
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            final size = await entity.length();

            String relativePath = entity.path.replaceFirst(dir.parent.path, '');
            if (relativePath.startsWith(PlatformUtils.pathSeparator)) {
              relativePath = relativePath.substring(1);
            }
            // Ensure URL friendly forward slashes
            relativePath = relativePath.replaceAll(
              PlatformUtils.pathSeparator,
              '/',
            );

            newFiles.add(
              SharedFile.fromPath(
                path: entity.path,
                name: relativePath,
                size: size,
              ),
            );
          }
        }
      } else {
        final size = await file.length();
        newFiles.add(
          SharedFile.fromPath(path: file.path, name: file.name, size: size),
        );
      }
    }
    return newFiles;
  }

  Future<bool> exists(String path) async {
    return File(path).exists();
  }
}
