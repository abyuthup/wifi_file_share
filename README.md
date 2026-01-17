# WiFi File Share

A streamlined Flutter desktop application designed for macOS that allows you to share files instantly over your local WiFi network. No internet connection required—just drag, drop, and share.

## Overview

WiFi File Share turns your computer into a local HTTP server, enabling you to share files with any device (phones, tablets, other computers) connected to the same network. It generates a unique link and QR code for each file, making transfer seamless.

## Features

- **🚀 Drag & Drop Interface:** Simply drag files onto the application window to start sharing.
- **📱 QR Code Sharing:** Generate a QR code for any shared file to instantly download it on mobile devices.
- **📺 Media Streaming:** Built-in support for HTTP Range requests allows smooth streaming of video and audio files without downloading them first.
- **🔒 Local Network Only:** Files are shared directly over your local WiFi, ensuring fast speeds and privacy. No data leaves your network.
- **🖥️ Desktop Optimized:** Built specifically for macOS with a native look and feel.

## Getting Started

1.  **Launch the App:** Open WiFi File Share on your macOS device.
2.  **Connect to WiFi:** Ensure your computer and the receiving device are connected to the ***same*** WiFi network.
3.  **Share Files:**
    - Drag and drop files into the app window.
    - OR use the "+" button (if available) to select files.
4.  **Access Files:**
    - Click the **QR Code** icon to scan with a mobile device.
    - Click **Copy Link** to share the URL manually.
    - Click **Open in Browser** to test the link yourself.

## How It Works

The application starts a local HTTP server on port 8080. When you add a file, it becomes accessible via a URL like `http://<your-ip>:8080/files/<filename>`.
- **Media Support:** The server automatically handles MIME types and supports partial content requests (Range headers), making it perfect for watching movies or listening to music directly from the browser.

## Tech Stack

- **Framework:** Flutter
- **Server:** Dart `dart:io` HttpServer
- **Dependencies:**
    - `desktop_drop` for drag-and-drop support.
    - `qr_flutter` for generating QR codes.
    - `mime` for file type detection.
    - `flutter_riverpod` for state management.
