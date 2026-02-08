//
//  PhotoWindow.m
//  SmallPhotoViewer
//

#import "PhotoWindow.h"
#import "CanvasView.h"
#import "SmallStep.h"
#import "SSWindowStyle.h"
#import "SSFileDialog.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

static const CGFloat kToolStripHeight = 36.0;
static const CGFloat kMargin = 8.0;

// Image extensions we support for viewing and folder navigation
static NSArray *allowedImageExtensions(void) {
    return [NSArray arrayWithObjects:@"png", @"jpg", @"jpeg", @"bmp", @"tiff", @"tif", @"gif", nil];
}

@interface ColorSwatchView : NSView
@property (nonatomic, strong) NSColor *fillColor;
@end
@implementation ColorSwatchView
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSColor *c = _fillColor ?: [NSColor blackColor];
    [c setFill];
    NSRectFill([self bounds]);
    [[NSColor grayColor] setStroke];
    NSFrameRect([self bounds]);
}
@end

/// Content view that accepts first responder and handles Left/Right for prev/next photo.
@interface PhotoContentView : NSView
@end
@implementation PhotoContentView
- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)event {
    unsigned short keyCode = [event keyCode];
    // Left = 123, Right = 124 (common on macOS/Linux)
    if (keyCode == 123) {
        [(PhotoWindow *)[self window] previousPhoto];
        return;
    }
    if (keyCode == 124) {
        [(PhotoWindow *)[self window] nextPhoto];
        return;
    }
    [super keyDown:event];
}
@end

@interface PhotoWindow () <CanvasViewDelegate>
@property (nonatomic, strong) PhotoContentView *contentContainer;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) CanvasView *canvasView;
@property (nonatomic, strong) NSView *toolStrip;
@property (nonatomic, strong) NSButton *pencilButton;
@property (nonatomic, strong) NSButton *eraserButton;
@property (nonatomic, strong) NSButton *colorButton;
@property (nonatomic, strong) ColorSwatchView *colorSwatch;
@property (nonatomic, copy) NSString *documentPath;
@property (nonatomic, assign) BOOL documentDirty;
@property (nonatomic, strong) NSArray *folderImagePaths;  // sorted paths in current folder
@property (nonatomic, assign) NSInteger currentFolderIndex;
@end

@implementation PhotoWindow

- (void)makeKeyAndOrderFront:(id)sender {
    [super makeKeyAndOrderFront:sender];
    [self makeFirstResponder:_contentContainer];
}

- (instancetype)init {
    NSUInteger style = [SSWindowStyle standardWindowMask];
    NSRect frame = NSMakeRect(100, 100, 700, 540);
    self = [super initWithContentRect:frame
                            styleMask:style
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (self) {
        [self setTitle:@"SmallPhotoViewer"];
        [self setReleasedWhenClosed:NO];
        _documentPath = nil;
        _documentDirty = NO;
        _folderImagePaths = [NSArray array];
        _currentFolderIndex = -1;
        [self buildContent];
    }
    return self;
}

#if defined(GNUSTEP) && !__has_feature(objc_arc)
- (void)dealloc {
    [_contentContainer release];
    [_scrollView release];
    [_canvasView release];
    [_toolStrip release];
    [_pencilButton release];
    [_eraserButton release];
    [_colorButton release];
    [_colorSwatch release];
    [_documentPath release];
    [_folderImagePaths release];
    [super dealloc];
}
#endif

- (void)buildContent {
    NSRect contentBounds = NSMakeRect(0, 0, 700, 540);
    _contentContainer = [[PhotoContentView alloc] initWithFrame:contentBounds];
    [_contentContainer setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setContentView:_contentContainer];

    CGFloat stripY = contentBounds.size.height - kToolStripHeight - kMargin;
    _toolStrip = [[NSView alloc] initWithFrame:NSMakeRect(0, stripY, contentBounds.size.width, kToolStripHeight)];
    [_toolStrip setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [_contentContainer addSubview:_toolStrip];

    CGFloat x = kMargin;
    _pencilButton = [[NSButton alloc] initWithFrame:NSMakeRect(x, 4, 70, 28)];
    [_pencilButton setTitle:@"Pencil"];
    [_pencilButton setButtonType:NSMomentaryPushInButton];
    [_pencilButton setBezelStyle:NSRoundedBezelStyle];
    [_pencilButton setTarget:self];
    [_pencilButton setAction:@selector(selectPencil:)];
    [_toolStrip addSubview:_pencilButton];
    x += 78;

    _eraserButton = [[NSButton alloc] initWithFrame:NSMakeRect(x, 4, 70, 28)];
    [_eraserButton setTitle:@"Eraser"];
    [_eraserButton setButtonType:NSMomentaryPushInButton];
    [_eraserButton setBezelStyle:NSRoundedBezelStyle];
    [_eraserButton setTarget:self];
    [_eraserButton setAction:@selector(selectEraser:)];
    [_toolStrip addSubview:_eraserButton];
    x += 78;

    _colorSwatch = [[ColorSwatchView alloc] initWithFrame:NSMakeRect(x, 6, 24, 24)];
    [_colorSwatch setFillColor:[NSColor blackColor]];
    [_toolStrip addSubview:_colorSwatch];

    _colorButton = [[NSButton alloc] initWithFrame:NSMakeRect(x + 28, 4, 60, 28)];
    [_colorButton setTitle:@"Color…"];
    [_colorButton setButtonType:NSMomentaryPushInButton];
    [_colorButton setBezelStyle:NSRoundedBezelStyle];
    [_colorButton setTarget:self];
    [_colorButton setAction:@selector(chooseColor:)];
    [_toolStrip addSubview:_colorButton];

    NSRect scrollFrame = NSMakeRect(0, 0, contentBounds.size.width, stripY);
    _scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
    [_scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:YES];
    [_scrollView setBorderType:NSBezelBorder];
    [_scrollView setAutohidesScrollers:YES];

    _canvasView = [[CanvasView alloc] initWithFrame:NSZeroRect];
    [_canvasView setDelegate:self];
    [_scrollView setDocumentView:_canvasView];
    [_contentContainer addSubview:_scrollView];

#if defined(GNUSTEP) && !__has_feature(objc_arc)
    [_scrollView release];
    [_canvasView release];
    [_toolStrip release];
    [_pencilButton release];
    [_eraserButton release];
    [_colorButton release];
    [_colorSwatch release];
#endif
}

- (void)selectPencil:(id)sender {
    (void)sender;
    [_canvasView setTool:0];
}

- (void)selectEraser:(id)sender {
    (void)sender;
    [_canvasView setTool:1];
}

- (void)chooseColor:(id)sender {
    (void)sender;
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    [panel setColor:[_canvasView foregroundColor]];
    [panel setTarget:self];
    [panel setAction:@selector(colorPanelChanged:)];
    [panel orderFront:nil];
}

- (void)colorPanelChanged:(id)sender {
    if ([sender isKindOfClass:[NSColorPanel class]]) {
        NSColor *c = [(NSColorPanel *)sender color];
        [_canvasView setForegroundColor:c];
        [_colorSwatch setFillColor:c];
        [_colorSwatch setNeedsDisplay:YES];
    }
}

- (void)canvasViewDidChange:(CanvasView *)canvasView {
    (void)canvasView;
    _documentDirty = YES;
    [self updateTitle];
}

- (void)updateTitle {
    NSString *name = _documentPath ? [_documentPath lastPathComponent] : @"SmallPhotoViewer";
    if (_documentDirty) name = [name stringByAppendingString:@" *"];
    NSInteger total = (NSInteger)[_folderImagePaths count];
    if (total > 0 && _currentFolderIndex >= 0) {
        name = [NSString stringWithFormat:@"%@ (%ld / %ld)", name, (long)(_currentFolderIndex + 1), (long)total];
    }
    [self setTitle:name];
}

/// Build sorted list of image paths in the same directory as path; sets current index to path.
- (void)rebuildFolderListForCurrentPath {
    if (!_documentPath.length) {
        _folderImagePaths = [NSArray array];
        _currentFolderIndex = -1;
        return;
    }
    NSString *dir = [_documentPath stringByDeletingLastPathComponent];
    NSString *currentName = [_documentPath lastPathComponent];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    NSArray *names = [fm contentsOfDirectoryAtPath:dir error:&err];
    if (!names) {
        _folderImagePaths = [NSArray array];
        _currentFolderIndex = -1;
        return;
    }
    NSMutableArray *paths = [NSMutableArray array];
    for (NSString *name in names) {
        NSString *ext = [[name pathExtension] lowercaseString];
        if ([allowedImageExtensions() containsObject:ext]) {
            [paths addObject:[dir stringByAppendingPathComponent:name]];
        }
    }
    [paths sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    _folderImagePaths = paths;
    _currentFolderIndex = -1;
    for (NSUInteger i = 0; i < [paths count]; i++) {
        if ([[[paths objectAtIndex:i] lastPathComponent] isEqualToString:currentName]) {
            _currentFolderIndex = (NSInteger)i;
            break;
        }
    }
}

- (void)openDocument {
    SSFileDialog *dialog = [SSFileDialog openDialog];
    [dialog setAllowedFileTypes:allowedImageExtensions()];
    NSArray *urls = [dialog showModal];
    if (!urls || [urls count] == 0) return;
    NSURL *url = [urls objectAtIndex:0];
    NSString *path = [url path];
    if (!path.length) return;
    if ([_canvasView setImageFromFile:path]) {
#if defined(GNUSTEP) && !__has_feature(objc_arc)
        [_documentPath release];
        _documentPath = [path copy];
#else
        _documentPath = [path copy];
#endif
        _documentDirty = NO;
        [self rebuildFolderListForCurrentPath];
        [self updateTitle];
    }
}

- (void)saveDocument {
    if (_documentPath.length) {
        [self saveToPath:_documentPath];
        return;
    }
    [self saveDocumentAs];
}

- (void)saveDocumentAs {
    SSFileDialog *dialog = [SSFileDialog saveDialog];
    [dialog setAllowedFileTypes:[NSArray arrayWithObjects:@"png", @"jpg", @"jpeg", nil]];
    NSArray *urls = [dialog showModal];
    if (!urls || [urls count] == 0) return;
    NSURL *url = [urls objectAtIndex:0];
    NSString *path = [url path];
    if (!path.length) return;
    if (![[path pathExtension] length])
        path = [path stringByAppendingPathExtension:@"png"];
    if ([self saveToPath:path]) {
#if defined(GNUSTEP) && !__has_feature(objc_arc)
        [_documentPath release];
        _documentPath = [path copy];
#else
        _documentPath = [path copy];
#endif
        _documentDirty = NO;
        [self rebuildFolderListForCurrentPath];
        [self updateTitle];
    }
}

- (BOOL)saveToPath:(NSString *)path {
    NSImage *img = [_canvasView image];
    if (!img) return NO;
    NSBitmapImageRep *rep = nil;
    for (NSImageRep *r in [img representations]) {
        if ([r isKindOfClass:[NSBitmapImageRep class]]) {
            rep = (NSBitmapImageRep *)r;
            break;
        }
    }
    if (!rep) {
        NSInteger w = (NSInteger)[img size].width;
        NSInteger h = (NSInteger)[img size].height;
        rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                     pixelsWide:w pixelsHigh:h
                                                  bitsPerSample:8 samplesPerPixel:4
                                                         hasAlpha:YES isPlanar:NO
                                                   colorSpaceName:NSDeviceRGBColorSpace
                                                      bytesPerRow:w * 4 bitsPerPixel:32];
        if (!rep) return NO;
        NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:ctx];
        [img drawInRect:NSMakeRect(0, 0, (CGFloat)w, (CGFloat)h) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
#if defined(GNUSTEP) && !__has_feature(objc_arc)
        [rep autorelease];
#endif
    }
    NSString *ext = [[path pathExtension] lowercaseString];
    NSBitmapImageFileType fileType = NSPNGFileType;
    if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"])
        fileType = NSJPEGFileType;
    NSData *data = [rep representationUsingType:fileType properties:[NSDictionary dictionary]];
    if (!data) return NO;
    return [data writeToFile:path atomically:YES];
}

- (void)previousPhoto {
    if (_currentFolderIndex <= 0) return;
    [self loadPhotoAtIndex:_currentFolderIndex - 1];
}

- (void)nextPhoto {
    if (_currentFolderIndex < 0 || _currentFolderIndex >= (NSInteger)[_folderImagePaths count] - 1) return;
    [self loadPhotoAtIndex:_currentFolderIndex + 1];
}

- (void)loadPhotoAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)[_folderImagePaths count]) return;
    NSString *path = [_folderImagePaths objectAtIndex:(NSUInteger)index];
    if ([_canvasView setImageFromFile:path]) {
#if defined(GNUSTEP) && !__has_feature(objc_arc)
        [_documentPath release];
        _documentPath = [path copy];
#else
        _documentPath = [path copy];
#endif
        _documentDirty = NO;
        _currentFolderIndex = index;
        [self updateTitle];
    }
}

@end
