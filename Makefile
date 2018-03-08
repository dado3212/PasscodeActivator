ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = PasscodeActivator
PasscodeActivator_FILES = Tweak.xm
PasscodeActivator_FRAMEWORKS = UIKit
PasscodeActivator_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += passcodeactivator
include $(THEOS_MAKE_PATH)/aggregate.mk
