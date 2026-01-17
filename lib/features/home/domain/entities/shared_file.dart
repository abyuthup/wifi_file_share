import 'package:mime/mime.dart';

class SharedFile {
  final String path;
  final String name;
  final int size;
  final String? mimeType;

  SharedFile({
    required this.path,
    required this.name,
    required this.size,
    this.mimeType,
  });

  factory SharedFile.fromPath({
    required String path,
    required String name,
    required int size,
  }) {
    final mime = lookupMimeType(path);
    return SharedFile(path: path, name: name, size: size, mimeType: mime);
  }

  Map<String, dynamic> toJson() {
    return {'path': path, 'name': name, 'size': size, 'mimeType': mimeType};
  }

  factory SharedFile.fromJson(Map<String, dynamic> json) {
    return SharedFile(
      path: json['path'],
      name: json['name'],
      size: json['size'],
      mimeType: json['mimeType'] ?? lookupMimeType(json['path']),
    );
  }
}
