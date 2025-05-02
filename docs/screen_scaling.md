# Screen Scaling Implementation

This document describes the implementation of screen scaling in the Kids Maze game.

## Overview

The game has been implemented to run in different resolutions while always scaling to the screen size and maintaining the aspect ratio. The game borders are treated as the borders of the tilemap.

## Implementation Details

The screen scaling is implemented in the `scripts/maze/maze.gd` script. The key components are:

1. **Camera Setup**: A Camera2D node is dynamically created in the `setup_camera()` function.

2. **Tilemap Boundary Detection**: The `get_tilemap_rect()` function calculates the boundaries of the tilemap by examining all used cells in both the ground and obstacles layers.

3. **Camera Update**: The `update_camera()` function handles both positioning the camera at the center of the tilemap and calculating the appropriate zoom factor to ensure the entire tilemap is visible while maintaining the aspect ratio.

4. **Window Resize Handling**: The script connects to the window's `size_changed` signal to automatically call `update_camera()` when the window is resized.

## Project Settings

The following project settings have been configured to support screen scaling:

```
[display]
window/size/viewport_width=800
window/size/viewport_height=950
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

These settings ensure that:
- The window is resizable by the user
- The canvas items are stretched to fit the window
- The aspect ratio is maintained during stretching

## Debug Visualization

A debug visualization feature has been added to help visualize the tilemap boundaries and how the scaling is working. This is particularly useful during development and testing.

### How to Use Debug Visualization

1. **Toggle Debug Mode**: Press the F1 key to toggle debug visualization on/off.

2. **Visual Elements**:
   - Red rectangle: Represents the boundaries of the tilemap
   - Green rectangle: Represents the current viewport boundaries
   - Red dot: Center of the tilemap
   - Green dot: Position of the camera

### Implementation

The debug visualization is implemented in the `scripts/maze/debug_visualizer.gd` script, which is dynamically loaded by the maze script when debug mode is enabled.

## Testing

To test the screen scaling:

1. Run the game
2. Resize the window to different dimensions
3. Observe how the game scales while maintaining aspect ratio
4. Press F1 to enable debug visualization and see the tilemap and viewport boundaries
5. Resize the window again to see how the boundaries adjust

## Notes

- The implementation ensures that the entire tilemap is always visible, regardless of the window size or aspect ratio.
- The camera is positioned at the center of the tilemap to provide a balanced view.
- The debug visualization can be disabled in production by setting `debug_mode = false` in the maze script.
