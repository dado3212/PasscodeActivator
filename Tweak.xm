#import <substrate.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFNotificationCenter.h>
#include <libactivator/libactivator.h>

static NSString *eventFormat = @"com.hackingdartmouth.passcodeactivator.passcode"; 
static NSString *prefPath = @"/var/mobile/Library/Preferences/com.hackingdartmouth.passcodeactivator.plist";

@interface PasscodeEvent: NSObject <LAEventDataSource> {
NSString *passcode;
}
+ (void)load:(NSString *)code;
@end

@implementation PasscodeEvent

PasscodeEvent *_passcodeEvent;

+ (void)load:(NSString *)code {
	@autoreleasepool {
		_passcodeEvent = [[PasscodeEvent alloc] init:code];
	}
}

- (id)init:(NSString *)code {
	if ((self = [super init])) {
		passcode = code;
		[LASharedActivator registerEventDataSource:self forEventName:[NSString stringWithFormat:@"%@-%@", eventFormat, passcode]];
	}
	return self;
}

- (void)dealloc {
	[LASharedActivator unregisterEventDataSourceWithEventName:[NSString stringWithFormat:@"%@-%@", eventFormat, passcode]];
	[super dealloc];
}

- (NSString *)localizedTitleForEventName:(NSString *)eventName {
	return @"Passcode Entered";
}

- (NSString *)localizedGroupForEventName:(NSString *)eventName {
	return @"Passcode";
}

- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
	return [[[[eventName componentsSeparatedByString:@"."] lastObject] componentsSeparatedByString:@"-"] lastObject];
}

- (BOOL)eventWithName:(NSString *)eventName isCompatibleWithMode:(NSString *)eventMode {
	if ([eventMode isEqualToString:@"lockscreen"]) {
		return true;
	} else {
		return false;
	}
}
 
@end


%hook SBDeviceLockController

- (BOOL)attemptDeviceUnlockWithPassword:(NSString *)passcode appRequested:(BOOL)requested {
	BOOL response = %orig;
	if (![passcode isKindOfClass:[NSString class]]) {
		return response;
	}

	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 CFSTR("com.hackingdartmouth.passcodeactivator.activateEvent"), 
										 NULL, 
										 (__bridge CFDictionaryRef)@{@"passcode": passcode}, 
										 kCFNotificationDeliverImmediately);

	return response;
}

%end

%hook SBUIPasscodeEntryField

-(void)_resetForFailedPasscode:(BOOL)arg1 playUnlockFailedSound:(BOOL)arg2 {
	if ([LASharedActivator hasEventWithName:[NSString stringWithFormat:@"%@-%@", eventFormat, [self stringValue]]]) {
		// makes it so it doesn't vibrate if it does something
		%orig(arg1, false);
	} else {
		%orig;
	}
}

%end

void updateEvents(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSDictionary *update = (__bridge NSDictionary*)userInfo;
	if ([update objectForKey:@"remove"]) { // unassign the event, and unregister the source
		LAEvent *event = [LAEvent eventWithName:[NSString stringWithFormat:@"%@-%@", eventFormat, [update objectForKey:@"remove"]] mode:@"lockscreen"];
		[LASharedActivator unassignEvent:event];
		[LASharedActivator unregisterEventDataSourceWithEventName:[NSString stringWithFormat:@"%@-%@", eventFormat, [update objectForKey:@"remove"]]];
	} else if ([update objectForKey:@"old"]) { // create new one, get old and new events, remove all listeners from old, add all of them to new
		[PasscodeEvent load:[update objectForKey:@"new"]];
		LAEvent *oldEvent = [LAEvent eventWithName:[NSString stringWithFormat:@"%@-%@", eventFormat, [update objectForKey:@"old"]] mode:@"lockscreen"];
		LAEvent *newEvent = [LAEvent eventWithName:[NSString stringWithFormat:@"%@-%@", eventFormat, [update objectForKey:@"new"]] mode:@"lockscreen"];
		NSArray *assigned = [LASharedActivator assignedListenerNamesForEvent:oldEvent];
		[LASharedActivator assignEvent:newEvent toListenersWithNames:assigned];
		[LASharedActivator unassignEvent:oldEvent];
		[LASharedActivator unregisterEventDataSourceWithEventName:[NSString stringWithFormat:@"%@-%@", eventFormat, [update objectForKey:@"old"]]];
	} else {
		[PasscodeEvent load:[update objectForKey:@"new"]];
	}
}

void activateEvent(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSDictionary *eventData = (__bridge NSDictionary*)userInfo;

	LAEvent *event = [LAEvent eventWithName:[NSString stringWithFormat:@"%@-%@", eventFormat, [eventData objectForKey:@"passcode"]] mode:[LASharedActivator currentEventMode]];
	[LASharedActivator sendEventToListener:event];
}

%ctor {
	// Construct notification listener
	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
								NULL,
								&updateEvents,
								CFSTR("com.hackingdartmouth.passcodeactivator.updateEvents"),
								NULL,
								CFNotificationSuspensionBehaviorDeliverImmediately);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
								NULL,
								&activateEvent,
								CFSTR("com.hackingdartmouth.passcodeactivator.activateEvent"),
								NULL,
								CFNotificationSuspensionBehaviorDeliverImmediately);

	// Rebuild from file
	NSMutableArray *rawSpecs = [[NSMutableArray alloc] initWithContentsOfFile:prefPath];
	for (NSArray *rawSpec in rawSpecs) {
		[PasscodeEvent load:[rawSpec objectAtIndex:1]];
	}
}
