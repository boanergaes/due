import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();
  static const String fallbackDeviceName = 'Due Mobile';

  /// Synchronous access to the detected device name.
  static String currentName = fallbackDeviceName;

  @visibleForTesting
  static void setMockDeviceName(String? name) {
    currentName = name ?? fallbackDeviceName;
  }

  static void refresh() {
    currentName = fallbackDeviceName;
  }

  /// Acquire device name dynamically across platforms, with 'Due Mobile' as the default fallback.
  static Future<String> getDeviceName() async {
    if (currentName != fallbackDeviceName) {
      return currentName;
    }

    try {
      if (kIsWeb) {
        final webInfo = await _plugin.webBrowserInfo;
        final browser = webInfo.browserName.name.toUpperCase();
        currentName = browser.isNotEmpty ? 'Web ($browser)' : fallbackDeviceName;
        return currentName;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final androidInfo = await _plugin.androidInfo;
          final manufacturer = androidInfo.manufacturer.trim();
          final model = androidInfo.model.trim();
          final brand = androidInfo.brand.trim();

          String effectiveMfr = manufacturer.isNotEmpty ? manufacturer : brand;
          if (effectiveMfr.isNotEmpty) {
            effectiveMfr = effectiveMfr[0].toUpperCase() + effectiveMfr.substring(1);
          }

          if (model.isNotEmpty) {
            if (effectiveMfr.isNotEmpty &&
                !model.toLowerCase().contains(effectiveMfr.toLowerCase())) {
              currentName = '$effectiveMfr $model';
            } else {
              currentName = model;
            }
          } else if (effectiveMfr.isNotEmpty) {
            currentName = effectiveMfr;
          } else {
            currentName = fallbackDeviceName;
          }
          break;

        case TargetPlatform.iOS:
          final iosInfo = await _plugin.iosInfo;
          final name = iosInfo.name.trim();
          final machine = iosInfo.utsname.machine.trim();
          if (name.isNotEmpty) {
            currentName = name;
          } else if (machine.isNotEmpty) {
            currentName = machine;
          } else {
            currentName = fallbackDeviceName;
          }
          break;

        case TargetPlatform.linux:
          final linuxInfo = await _plugin.linuxInfo;
          currentName = linuxInfo.prettyName.isNotEmpty
              ? linuxInfo.prettyName
              : 'Linux Device';
          break;

        case TargetPlatform.macOS:
          final macInfo = await _plugin.macOsInfo;
          currentName = macInfo.computerName.isNotEmpty
              ? macInfo.computerName
              : 'Mac Device';
          break;

        case TargetPlatform.windows:
          final winInfo = await _plugin.windowsInfo;
          currentName = winInfo.computerName.isNotEmpty
              ? winInfo.computerName
              : 'Windows Device';
          break;

        default:
          currentName = fallbackDeviceName;
      }
    } catch (_) {
      currentName = fallbackDeviceName;
    }

    if (currentName.trim().isEmpty) {
      currentName = fallbackDeviceName;
    }

    return currentName;
  }
}
