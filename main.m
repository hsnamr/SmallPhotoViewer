//
//  main.m
//  SmallPhotoViewer
//
//  Photo viewer with basic editing for GNUstep. Uses SmallStepLib and shared
//  CanvasView from SmallPaint. Left/Right keys navigate previous/next photo.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "AppDelegate.h"
#import "SmallStep.h"

int main(int argc, const char *argv[]) {
#if defined(GNUSTEP) && !__has_feature(objc_arc)
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#endif
    id<SSAppDelegate> delegate = [[AppDelegate alloc] init];
    [SSHostApplication runWithDelegate:delegate];
#if defined(GNUSTEP) && !__has_feature(objc_arc)
    [delegate release];
    [pool release];
#endif
    return 0;
}
