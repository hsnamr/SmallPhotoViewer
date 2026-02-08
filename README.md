# SmallPhotoViewer

A photo viewer with basic editing tools for GNUstep. Uses [SmallStepLib](../SmallStepLib) for app lifecycle, menus, window style, and file dialogs, and shares the canvas and editing UI with [SmallPaint](../SmallPaint).

## Features

- **Open** an image (PNG, JPEG, BMP, TIFF, GIF). The app builds a list of all images in the same folder.
- **Navigate** to previous and next photo in the folder with the **Left** and **Right** arrow keys (or via menu: Previous / Next).
- **Basic editing** using the same tools as SmallPaint: Pencil, Eraser, and color picker. Edits apply to the current image.
- **Save** / **Save As** to write the current image (including edits) to disk.

## Build

1. Build and install SmallStepLib:

   ```bash
   cd ../SmallStepLib && make && make install
   ```

2. Build SmallPhotoViewer:

   ```bash
   cd ../SmallPhotoViewer
   make
   ```

3. Run:

   ```bash
   ./SmallPhotoViewer.app/SmallPhotoViewer
   ```
   or from the build directory: `openapp ./SmallPhotoViewer.app`

## Dependencies

- GNUstep (gui, base)
- [SmallStepLib](../SmallStepLib) (installed)
- [SmallPaint](../SmallPaint) source (only `Canvas/CanvasView` is compiled in; no need to build SmallPaint first)
