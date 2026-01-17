import 'package:cross_file/cross_file.dart';
import '../../../features/home/domain/entities/shared_file.dart';

class FileHelper {
  Future<List<SharedFile>> processFiles(List<XFile> files) async {
    final newFiles = <SharedFile>[];
    for (final file in files) {
      final size = await file.length();
      newFiles.add(
        SharedFile.fromPath(path: file.path, name: file.name, size: size),
      );
    }
    return newFiles;
  }

  Future<bool> exists(String path) async {
    // on Web, paths are blob URLs usually, persistence is tricky.
    // Assume false for persistence checks to avoid loading stale blobs.
    return false;
  }
}
