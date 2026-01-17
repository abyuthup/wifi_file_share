import 'package:desktop_drop/desktop_drop.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/home_provider.dart';
import '../widgets/server_status_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      body: DropTarget(
        // Desktop Drop
        onDragDone: (details) {
          notifier.addFiles(details.files);
        },
        onDragEntered: (details) {
          notifier.setDragging(true);
        },
        onDragExited: (details) {
          notifier.setDragging(false);
        },
        child: Container(
          color: homeState.isDragging
              ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50)
              : Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                  left: 24.0,
                  right: 24.0,
                ),
                child: Text(
                  'WiFi File Share',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),

              // Server Status
              const ServerStatusWidget(),

              // Drag Area or File List
              Expanded(
                child: homeState.sharedFiles.isEmpty
                    ? _buildEmptyState(context, homeState.isDragging)
                    : _buildFileList(context, ref, homeState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDragging) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: isDragging
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDragging ? Theme.of(context).primaryColor : Colors.grey,
              width: 2,
              style: isDragging
                  ? BorderStyle.solid
                  : BorderStyle
                        .none, // Solid when dragging, none (or dashed if implemented) when not
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: isDragging
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Drag & Drop files here to share',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDragging
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileList(
    BuildContext context,
    WidgetRef ref,
    dynamic homeState,
  ) {
    final ip = homeState.serverIp;
    final port = homeState.port;
    final fileList = homeState.sharedFiles;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fileList.length,
      itemBuilder: (context, index) {
        final file = fileList[index];
        final fileUrl = ip != null
            ? 'http://$ip:$port/files/${Uri.encodeComponent(file.name)}'
            : null;

        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _getFileIcon(file.name),
            title: Text(file.name),
            subtitle: Text(
              '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fileUrl != null) ...[
                  IconButton(
                    tooltip: 'Copy Link',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: fileUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Open in Browser',
                    icon: const Icon(Icons.open_in_browser),
                    onPressed: () async {
                      if (await canLaunchUrl(Uri.parse(fileUrl))) {
                        await launchUrl(Uri.parse(fileUrl));
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'QR Code',
                    icon: const Icon(Icons.qr_code),
                    onPressed: () {
                      _showQrDialog(context, fileUrl);
                    },
                  ),
                ],
                const VerticalDivider(width: 16, indent: 8, endIndent: 8),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    ref.read(homeProvider.notifier).removeFile(file);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Icon _getFileIcon(String filename) {
    String ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return const Icon(Icons.image, color: Colors.purple);
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return const Icon(Icons.movie, color: Colors.red);
      case 'mp3':
      case 'wav':
        return const Icon(Icons.audiotrack, color: Colors.blue);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.redAccent);
      case 'zip':
      case 'rar':
      case '7z':
        return const Icon(Icons.folder_zip, color: Colors.orange);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  void _showQrDialog(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan to Download',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(data: data, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 16),
              SelectableText(
                data,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
