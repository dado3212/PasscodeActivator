#import <Preferences/Preferences.h>

@interface PasscodeActivatorListController: PSListController {
}
@end

@implementation PasscodeActivatorListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"PasscodeActivator" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
