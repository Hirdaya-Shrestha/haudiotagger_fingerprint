#include "include/haudiotagger_fingerprint/haudio_fingerprint_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "haudiotagger_fingerprint_plugin.h"

void HaudioFingerprintPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  haudiotagger_fingerprint::HaudioFingerprintPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
