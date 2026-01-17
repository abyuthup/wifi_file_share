import 'dart:io';

class NetworkInfoService {
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        // Filter for standard interfaces (en0, wlan0 usually)
        // Ignoring loopback and generic link-locals if possible,
        // but typically the first non-loopback IPv4 is what we want.
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting IP: $e');
    }
    return null;
  }
}
