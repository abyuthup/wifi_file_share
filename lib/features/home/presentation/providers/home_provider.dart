import 'dart:convert';
import 'dart:typed_data'; // for Uint8List
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/shared_file.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/server/local_file_server.dart';
import '../../../../core/utils/files/file_helper.dart';

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
  final FileHelper _fileHelper = FileHelper();
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
    // Auto-start only if IP is found (meaning likely supported)
    if (ip != null) {
      await startServer();
    }
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
          if (await _fileHelper.exists(file.path)) {
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
    final newFiles = await _fileHelper.processFiles(files);

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

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true, // Required to get bytes on Web
      );

      if (result != null) {
        // Native: Prefer paths if available
        if (result.paths.isNotEmpty && result.paths.any((p) => p != null)) {
          final xFiles = result.paths
              .where((path) => path != null)
              .map((path) => XFile(path!))
              .toList();
          addFiles(xFiles);
          return;
        }

        // Web: Paths are null, use bytes
        if (result.files.isNotEmpty) {
          final xFiles = result.files.map((f) {
            return XFile.fromData(
              f.bytes ?? Uint8List(0),
              name: f.name,
              length: f.size,
            );
          }).toList();
          addFiles(xFiles);
        }
      }
    } catch (e) {
      print('Pick error: $e');
    }
  }
}

// Provider
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
