#import <Preferences/Preferences.h>
#import <libactivator/libactivator.h>
#import <CoreFoundation/CFNotificationCenter.h>

@interface PasscodeActivatorEditableListController: PSEditableListController
@end

@implementation PasscodeActivatorEditableListController
NSString *prefPath = @"/var/mobile/Library/Preferences/com.hackingdartmouth.passcodeactivator.plist";

PSSpecifier *lastEdited = nil;
 
extern NSString* PSDeletionActionKey;

// -------------------
//|	  Custom Methods  |
// -------------------
- (void) saveActivators {
	NSMutableArray *specs = [[NSMutableArray alloc] init];
	for (int i = 0; i < _specifiers.count; i++) {
		PSSpecifier *spec = [_specifiers objectAtIndex:i];
		if (spec.cellType == 4) {
			NSString *name = [spec name];
			NSString *value = [spec propertyForKey:@"value"];
			NSArray *tempSpec = [[NSArray alloc] initWithObjects:name, value, nil];
			[specs addObject:tempSpec];
		}
	}
	[specs writeToFile:prefPath atomically:YES];
}

- (PSSpecifier *)createSpecNamed:(NSString *)name value:(NSString *)value {
	PSSpecifier *tempSpec = [PSSpecifier preferenceSpecifierNamed:name
		target:self
		set:NULL
		get:@selector(getValue:)
		detail:Nil
		cell:PSTitleValueCell
		edit:Nil];
	[tempSpec setProperty:value forKey:@"value"];
	[tempSpec setButtonAction:@selector(editCode:)];
	[tempSpec setProperty:NSStringFromSelector(@selector(deletedCode:)) forKey:PSDeletionActionKey];
	return tempSpec;
}

- (NSString *)getValue: (PSSpecifier *) spec {
    return [spec propertyForKey:@"value"];
}

- (void)addCode {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create Passcode"
		message:@""
		delegate:self
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil];
	alertView.tag = 2;
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alertView show];
}

- (void)editCode: (PSSpecifier *) spec {
	lastEdited = spec;
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Edit Passcode"
		message:@""
		delegate:self
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil];
	alertView.tag = 2;
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	[[alertView textFieldAtIndex:0] setText:[NSString stringWithFormat:@"%@", [spec propertyForKey:@"value"]]];
	[alertView show];
}

- (void) deletedCode:(PSSpecifier*)specifier {
	NSMutableArray *itemsCopy = [_specifiers mutableCopy];
	[itemsCopy removeObject:specifier];
	_specifiers = [[NSArray arrayWithArray:itemsCopy] retain];

	for (int i = 1; i < _specifiers.count; i++) {
		[[_specifiers objectAtIndex:i] setName:[NSString stringWithFormat:@"Passcode %d", i]];
	}

	// Tell SpringBoard to update events
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 CFSTR("com.hackingdartmouth.passcodeactivator.updateEvents"), 
										 NULL, 
										 (__bridge CFDictionaryRef)@{@"remove": [specifier propertyForKey:@"value"]}, 
										 kCFNotificationDeliverImmediately);

	[self saveActivators];
	[self reloadSpecifiers];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	NSString *pass = [[alertView textFieldAtIndex:0] text];
	NSDictionary *specData;
	if ([alertView.title isEqualToString:@"Create Passcode"]) { // create passcode

		// Adds a passcode object
		NSMutableArray *specs = [(NSArray*)_specifiers mutableCopy];
		PSSpecifier* tempSpec = [self createSpecNamed:[NSString stringWithFormat:@"Passcode %d", (int)[specs count]] value:pass];
		[specs addObject:tempSpec];
		_specifiers = [[NSArray arrayWithArray:specs] retain];
		specData = @{@"new": pass}; //[NSDictionary dictionaryWithObject:pass forKey:@"new"];

	} else { // save modified passcode
		specData = @{@"new": pass, @"old": [lastEdited propertyForKey:@"value"]};
		[lastEdited setProperty:pass forKey:@"value"];
	}

	// Tell SpringBoard to update events
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 CFSTR("com.hackingdartmouth.passcodeactivator.updateEvents"), 
										 NULL, 
										 (__bridge CFDictionaryRef)specData, 
										 kCFNotificationDeliverImmediately);

	[self saveActivators];
	[self reloadSpecifiers];
}

// -------------------
//|	 Override Methods |
// -------------------

- (id)specifiers {
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray array];
		// initialize with group name
		PSSpecifier* testSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Passcode Activators"
			target:self
			set:NULL
			get:NULL
			detail:Nil
			cell:PSGroupCell
			edit:Nil];
		[specs addObject:testSpecifier];
		NSMutableArray *rawSpecs = [[NSMutableArray alloc] initWithContentsOfFile:prefPath];
		for (NSArray *rawSpec in rawSpecs) {
			PSSpecifier* tempSpec = [self createSpecNamed:[rawSpec objectAtIndex:0] value:[rawSpec objectAtIndex:1]];
			[specs addObject:tempSpec];
		}

		_specifiers = [[NSArray arrayWithArray:specs] retain];
	}

	return _specifiers;
}

- (void)_updateNavigationBar {
	[super _updateNavigationBar];
	UINavigationItem *nav = self.navigationItem;
	NSMutableArray *barItems = [(NSArray *)nav.rightBarButtonItems mutableCopy];

	if (barItems.count >= 1) {
		UIBarButtonItem *currButton = [barItems objectAtIndex:0];
		if ([currButton.title isEqualToString:@"Edit"] && barItems.count == 1) { // edit page: add
			UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" 
					style:UIBarButtonItemStylePlain 
					target:self
					action:@selector(addCode)];
			addButton.tag = 1;

			[barItems addObject:addButton];
		} else if ([currButton.title isEqualToString:@"Done"]) { // done page: remove
			barItems = [NSMutableArray arrayWithObjects:currButton, nil];
		}		
	}

	[nav setRightBarButtonItems:[[NSArray arrayWithArray:barItems] retain]];
}

@end
