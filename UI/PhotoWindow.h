//
//  PhotoWindow.h
//  SmallPhotoViewer
//
//  Main window: photo in scroll view with CanvasView (shared with SmallPaint)
//  for display and basic editing. Left/Right keys navigate folder. Open/Save
//  via SSFileDialog.
//

#import <AppKit/AppKit.h>

@interface PhotoWindow : NSWindow

- (void)openDocument;
- (void)saveDocument;
- (void)saveDocumentAs;
- (void)previousPhoto;
- (void)nextPhoto;

@end
