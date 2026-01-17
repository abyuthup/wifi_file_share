import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/platform_utils.dart';
import '../providers/home_provider.dart';

class ServerStatusWidget extends ConsumerWidget {
  const ServerStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    if (PlatformUtils.isWeb) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const ListTile(
          leading: Icon(Icons.public, color: Colors.blue),
          title: Text('Web Preview Mode'),
          subtitle: Text('Hosting files is not supported in the browser.'),
        ),
      );
    }

    final ip = homeState.serverIp ?? 'Unknown IP';
    final port = homeState.port;
    final url = 'http://$ip:$port';
    final isRunning = homeState.isServerRunning;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: isRunning ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRunning ? 'Server Active' : 'Server Stopped',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isRunning ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isRunning)
                          Text(
                            url,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: isRunning,
                  onChanged: (value) => notifier.toggleServer(),
                ),
              ],
            ),
            if (isRunning) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Accessible only on local network',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Root URL'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
