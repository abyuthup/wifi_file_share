import 'dart:io';
import 'dart:async';
import 'package:mime/mime.dart';
import '../../features/home/domain/entities/shared_file.dart';

class LocalFileServer {
  HttpServer? _server;
  final int port;
  final List<SharedFile> Function() getSharedFiles;

  LocalFileServer({this.port = 8080, required this.getSharedFiles});

  Future<void> start() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('Server running on port $port');
      _server!.listen(_handleRequest);
    } catch (e) {
      print('Error starting server: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    print('Server stopped');
  }

  void _handleRequest(HttpRequest request) {
    if (request.method == 'GET') {
      _handleGet(request);
    } else {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..close();
    }
  }

  void _handleGet(HttpRequest request) async {
    final pathSegments = request.uri.pathSegments;
    // URL format: /files/<filename>

    if (pathSegments.length < 2 || pathSegments[0] != 'files') {
      _sendNotFound(request);
      return;
    }

    final filename = Uri.decodeComponent(
      pathSegments[1],
    ); // Handle spaces/special chars
    final files = getSharedFiles();

    try {
      final fileEntity = files.firstWhere((f) => f.name == filename);
      final file = File(fileEntity.path);

      if (!await file.exists()) {
        _sendNotFound(request);
        return;
      }

      final length = await file.length();
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      // Range Request Handling
      final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

      if (rangeHeader != null) {
        _handleRangeRequest(request, file, length, mimeType, rangeHeader);
      } else {
        request.response.headers.contentType = ContentType.parse(mimeType);
        request.response.headers.contentLength = length;
        request.response.headers.add('Accept-Ranges', 'bytes');
        request.response.headers.add(
          'Content-Disposition',
          'attachment; filename="$filename"',
        ); // Optional: force download vs inline
        await file.openRead().pipe(request.response);
      }
    } catch (e) {
      print('File not found in shared list or error: $e');
      _sendNotFound(request);
    }
  }

  void _handleRangeRequest(
    HttpRequest request,
    File file,
    int fileLength,
    String mimeType,
    String rangeHeader,
  ) async {
    // Basic Range parsing: bytes=start-end
    try {
      final ranges = rangeHeader.split('=');
      if (ranges.length != 2 || ranges[0] != 'bytes') {
        // Invalid range
        _sendError(request, HttpStatus.requestedRangeNotSatisfiable);
        return;
      }

      final rangeParts = ranges[1].split('-');
      int start = int.parse(rangeParts[0]);
      int end = rangeParts.length > 1 && rangeParts[1].isNotEmpty
          ? int.parse(rangeParts[1])
          : fileLength - 1;

      if (start >= fileLength || end >= fileLength || start > end) {
        _sendError(request, HttpStatus.requestedRangeNotSatisfiable);
        return;
      }

      final contentLength = end - start + 1;

      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.contentType = ContentType.parse(mimeType);
      request.response.headers.add(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$end/$fileLength',
      );
      request.response.headers.contentLength = contentLength;
      request.response.headers.add('Accept-Ranges', 'bytes');

      await file.openRead(start, end + 1).pipe(request.response);
    } catch (e) {
      _sendError(request, HttpStatus.internalServerError);
    }
  }

  void _sendNotFound(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write('File not found')
      ..close();
  }

  void _sendError(HttpRequest request, int code) {
    request.response
      ..statusCode = code
      ..close();
  }
}
