#import <substrate.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#include <libactivator/libactivator.h>

// settings

%hook SBDeviceLockController
- (BOOL)attemptDeviceUnlockWithPassword:(NSString *)passcode appRequested:(BOOL)requested
{
	if (![passcode isKindOfClass:[NSString class]])
		return %orig;
	NSDictionary *prefs=[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.hackingdartmouth.passcodeactivator.plist"];
	if ([[prefs objectForKey:@"enabled"] boolValue]) {
		NSString *match=[prefs objectForKey:@"code"];
		if ([match isEqualToString:passcode]) {
			LAEvent *event = [LAEvent eventWithName:@"com.hackingdartmouth.passcodeactivator.passcode" mode:[LASharedActivator currentEventMode]];
			[LASharedActivator sendEventToListener:event];
		}
	}

	return %orig;
}

%end