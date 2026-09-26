#import "HaudioFingerprintPlugin.h"
#if __has_include(<haudiotagger_fingerprint/haudiotagger_fingerprint-Swift.h>)
#import <haudiotagger_fingerprint/haudiotagger_fingerprint-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "haudiotagger_fingerprint-Swift.h"
#endif

@implementation HaudioFingerprintPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftHaudioFingerprintPlugin registerWithRegistrar:registrar];
}
@end
