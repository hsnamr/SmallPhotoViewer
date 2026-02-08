# GNUmakefile for SmallPhotoViewer (Linux/GNUstep)
#
# Photo viewer with basic editing. Uses SmallStepLib for app lifecycle,
# menus, window style, and file dialogs. Shares CanvasView with SmallPaint
# for display and editing. Left/Right keys navigate previous/next photo.
#
# Build SmallStepLib first: cd ../SmallStepLib && make && make install
# Then: make

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = SmallPhotoViewer

SmallPhotoViewer_OBJC_FILES = \
	main.m \
	App/AppDelegate.m \
	UI/PhotoWindow.m

SmallPhotoViewer_HEADER_FILES = \
	App/AppDelegate.h \
	UI/PhotoWindow.h

SmallPhotoViewer_INCLUDE_DIRS = \
	-I. \
	-IApp \
	-IUI \
	-I../SmallStepLib/SmallStep/Core \
	-I../SmallStepLib/SmallStep/Platform/Linux

# SmallStep framework (from SmallStepLib)
SMALLSTEP_FRAMEWORK := $(shell find ../SmallStepLib -name "SmallStep.framework" -type d 2>/dev/null | head -1)
ifneq ($(SMALLSTEP_FRAMEWORK),)
  SMALLSTEP_LIB_DIR := $(shell cd $(SMALLSTEP_FRAMEWORK)/Versions/0 2>/dev/null && pwd)
  SMALLSTEP_LIB_PATH := -L$(SMALLSTEP_LIB_DIR)
  SMALLSTEP_LDFLAGS := -Wl,-rpath,$(SMALLSTEP_LIB_DIR)
else
  SMALLSTEP_LIB_PATH :=
  SMALLSTEP_LDFLAGS :=
endif

SmallPhotoViewer_LIBRARIES_DEPEND_UPON = -lobjc -lgnustep-gui -lgnustep-base
SmallPhotoViewer_LDFLAGS = $(SMALLSTEP_LIB_PATH) $(SMALLSTEP_LDFLAGS) -Wl,--allow-shlib-undefined
SmallPhotoViewer_ADDITIONAL_LDFLAGS = $(SMALLSTEP_LIB_PATH) $(SMALLSTEP_LDFLAGS) -lSmallStep
SmallPhotoViewer_TOOL_LIBS = -lSmallStep -lobjc

include $(GNUSTEP_MAKEFILES)/application.make
