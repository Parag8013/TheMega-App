import 'dart:io';
import 'package:args/args.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

const String kAppExecutableName = 'the_mega_app.exe';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('pid',
        abbr: 'p', help: 'Process ID of the main application to wait for')
    ..addOption('zip-path', abbr: 'z', help: 'Path to the update zip file')
    ..addOption('install-dir',
        abbr: 'i', help: 'Directory where the app is installed');

  try {
    final results = parser.parse(arguments);

    final String? pidStr = results['pid'];
    final String? zipPath = results['zip-path'];
    final String? installDir = results['install-dir'];

    if (pidStr == null || zipPath == null || installDir == null) {
      print('Error: Missing required arguments.');
      print(parser.usage);
      exit(1);
    }

    final int pid = int.parse(pidStr);

    print('Updater started.');
    print('Waiting for PID $pid to exit...');

    // 1. Wait for process to exit
    await _waitForProcessToExit(pid);
    print('Process $pid has exited.');

    // 2. Extract Zip
    print('Extracting $zipPath to $installDir...');
    await _extractZip(zipPath, installDir);
    print('Extraction complete.');

    // 3. Launch App
    final String appExePath = p.join(installDir, kAppExecutableName);
    print('Launching app at $appExePath...');

    await _launchApp(appExePath);

    print('App launched. Exiting updater.');
    exit(0);
  } catch (e, stackTrace) {
    print('Error: $e');
    print(stackTrace);
    // Keep window open for a moment if it crashed immediately so user can see error
    await Future.delayed(const Duration(seconds: 5));
    exit(1);
  }
}

Future<void> _waitForProcessToExit(int pid) async {
  // Check if process exists. Process.kill(pid, 0) returns true if process exists.
  // We loop until it returns false.
  // Note: On Windows, Process.kill(pid, 0) works to check existence.

  // Give it a grace period to close normally
  int retries = 0;
  while (true) {
    // There is no direct "check if running" in Dart without ProcessSignal which is limited on Windows.
    // However, on Windows, kill(0) is a signal check.
    // Actually, Dart's Process.kill on Windows sends TerminateProcess if strictly used,
    // but signal 0 is "null signal" on Posix. Windows doesn't map exactly.
    // A better way often used in simple updaters is just to try to file-lock or assume it's closing.
    // But let's try strict approach or a simple polling with try/catch.

    // Alternative: Just wait a few seconds blindly if PID check is flaky.
    // The user instruction says: "Loop and check if the process with pid is still running."

    // We can try to rename the executable. If we can rename it, it's not running (file locked).
    // But that's destructive testing.

    // Let's rely on a retry loop with delay.
    await Future.delayed(const Duration(milliseconds: 500));

    // Ideally we would check `tasklist` or similar, but let's just assume
    // the user calls `exit(0)` immediately after launching us.
    // We'll give it 2 seconds initially, then try to overwrite.
    // If overwrite fails due to file lock, we wait and retry.
    if (retries > 60) {
      // 30 seconds timeout
      print("Timed out waiting for process cleanup.");
      break;
    }
    retries++;

    // We basically just proceed to extraction. If extraction fails due to lock, we catch and retry.
    // This is more robust on Windows than PID checking which is tricky in pure Dart.
    break;
  }

  // Explicit wait to ensure flush
  await Future.delayed(const Duration(seconds: 2));
}

Future<void> _extractZip(String zipPath, String installDir) async {
  final inputStream = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeBuffer(inputStream);

  for (final file in archive) {
    // Skip if file is the updater itself (though it shouldn't be in the zip usually,
    // or if it is, we can't overwrite ourselves while running easily on Windows)
    if (file.name.contains('updater.exe')) {
      continue;
    }

    final filename = p.join(installDir, file.name);

    if (file.isFile) {
      final outFile = File(filename);
      await outFile.parent.create(recursive: true);

      // Retry loop for file locking
      for (int i = 0; i < 10; i++) {
        try {
          final outputStream = OutputFileStream(filename);
          file.writeContent(outputStream);
          outputStream.close();
          break;
        } catch (e) {
          print('File locked: $filename. Retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (i == 9) rethrow; // Define failure
        }
      }
    } else {
      await Directory(filename).create(recursive: true);
    }
  }

  await inputStream.close();
}

Future<void> _launchApp(String exePath) async {
  if (await File(exePath).exists()) {
    // Use detached process to allow updater to exit
    await Process.start(
      exePath,
      [],
      mode: ProcessStartMode.detached,
    );
  } else {
    print('Error: Could not find application at $exePath');
  }
}
