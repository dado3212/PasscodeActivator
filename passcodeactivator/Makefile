ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

BUNDLE_NAME = PasscodeActivator
PasscodeActivator_FILES = PasscodeActivator.mm
PasscodeActivator_INSTALL_PATH = /Library/PreferenceBundles
PasscodeActivator_FRAMEWORKS = UIKit
PasscodeActivator_PRIVATE_FRAMEWORKS = Preferences
PasscodeActivator_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PasscodeActivator.plist$(ECHO_END)
