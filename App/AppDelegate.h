//
//  AppDelegate.h
//  SmallPhotoViewer
//
//  App lifecycle and menu; creates the main photo viewer window.
//

#import <Foundation/Foundation.h>
#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#endif
#import "SmallStep.h"

@class PhotoWindow;

@interface AppDelegate : NSObject <SSAppDelegate>
{
    PhotoWindow *_mainWindow;
}
@end
