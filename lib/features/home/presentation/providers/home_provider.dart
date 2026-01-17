import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import '../../domain/entities/shared_file.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/server/local_file_server.dart';

// State class for Home
class HomeState {
  final List<SharedFile> sharedFiles;
  final bool isDragging;
  final String? serverIp;
  final bool isServerRunning;
  final int port;

  HomeState({
    this.sharedFiles = const [],
    this.isDragging = false,
    this.serverIp,
    this.isServerRunning = false,
    this.port = 8080,
  });

  HomeState copyWith({
    List<SharedFile>? sharedFiles,
    bool? isDragging,
    String? serverIp,
    bool? isServerRunning,
    int? port,
  }) {
    return HomeState(
      sharedFiles: sharedFiles ?? this.sharedFiles,
      isDragging: isDragging ?? this.isDragging,
      serverIp: serverIp ?? this.serverIp,
      isServerRunning: isServerRunning ?? this.isServerRunning,
      port: port ?? this.port,
    );
  }
}

// Notifier
class HomeNotifier extends Notifier<HomeState> {
  LocalFileServer? _server;
  final NetworkInfoService _networkInfo = NetworkInfoService();
  static const _storageKey = 'shared_files_list';

  @override
  HomeState build() {
    _init();
    return HomeState();
  }

  Future<void> _init() async {
    await _loadFiles();
    await _initServer();
  }

  Future<void> _initServer() async {
    final ip = await _networkInfo.getLocalIpAddress();
    state = state.copyWith(serverIp: ip);
    await startServer(); // Auto-start
  }

  Future<void> _loadFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey);

    if (jsonList != null) {
      final loadedFiles = <SharedFile>[];
      for (final jsonStr in jsonList) {
        try {
          final map = jsonDecode(jsonStr);
          final file = SharedFile.fromJson(map);
          if (File(file.path).existsSync()) {
            loadedFiles.add(file);
          }
        } catch (e) {
          // invalid entry
        }
      }
      state = state.copyWith(sharedFiles: loadedFiles);
    }
  }

  Future<void> _saveFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.sharedFiles
        .map((f) => jsonEncode(f.toJson()))
        .toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<void> startServer() async {
    if (state.isServerRunning) return;

    _server = LocalFileServer(
      port: state.port,
      getSharedFiles: () => state.sharedFiles,
    );
    await _server!.start();
    state = state.copyWith(isServerRunning: true);
  }

  Future<void> stopServer() async {
    if (!state.isServerRunning) return;
    await _server?.stop();
    _server = null;
    state = state.copyWith(isServerRunning: false);
  }

  Future<void> toggleServer() async {
    if (state.isServerRunning) {
      await stopServer();
    } else {
      await startServer();
    }
  }

  void setDragging(bool dragging) {
    state = state.copyWith(isDragging: dragging);
  }

  Future<void> addFiles(List<XFile> files) async {
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
            // Maintain relative path structure in name for generic sharing
            // ideally we'd use relative path from drop root, but for now simple recursion
            // using generic name is safer to avoid collisions if we handle uniqueness later.
            // But prompt says "Maintain folder structure in URLs".
            // To do that, we need to know the 'root' of the drop.
            // We'll use the relative path from the dropped directory.

            String relativePath = entity.path.replaceFirst(dir.parent.path, '');
            if (relativePath.startsWith(Platform.pathSeparator)) {
              relativePath = relativePath.substring(1);
            }
            // Ensure URL friendly forward slashes
            relativePath = relativePath.replaceAll(Platform.pathSeparator, '/');

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

    state = state.copyWith(
      sharedFiles: [...state.sharedFiles, ...newFiles],
      isDragging: false,
    );
    _saveFiles();
  }

  void removeFile(SharedFile file) {
    state = state.copyWith(
      sharedFiles: state.sharedFiles.where((f) => f != file).toList(),
    );
    _saveFiles();
  }

  void clearFiles() {
    state = state.copyWith(sharedFiles: []);
    _saveFiles();
  }
}

// Provider
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
