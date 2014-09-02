
export THEOS_DEVICE_IP=localhost
export THEOS_DEVICE_PORT=2222

ARCHS = armv7s

include theos/makefiles/common.mk

TWEAK_NAME = JumpController
JumpController_FILES = JumpPointer/JumpPointer.m NSObject+Debounce/NSObject+Debounce.m Tweak.xm
JumpController_FRAMEWORKS = Foundation UIKit
JumpController_LDFLAGS = -L./lib -lJump -lrocketbootstrap -lsimulatetouch -lactivator

THEOS_BUILD_DIR = debs

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
