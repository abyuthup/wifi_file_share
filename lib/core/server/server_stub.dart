import 'dart:async';
import '../../features/home/domain/entities/shared_file.dart';

class LocalFileServer {
  final int port;
  final List<SharedFile> Function() getSharedFiles;

  LocalFileServer({this.port = 8080, required this.getSharedFiles});

  Future<void> start() async {
    print('Server not supported on Web');
  }

  Future<void> stop() async {
    // No-op
  }
}
