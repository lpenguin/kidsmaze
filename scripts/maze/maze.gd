# scripts/maze/maze.gd
extends Node2D

# Reference to the tilemap layers for calculating boundaries
@onready var ground_layer: TileMapLayer = $GroundTileMapLayer
@onready var obstacles_layer: TileMapLayer = $ObstaclesTileMapLayer

# Camera for handling screen scaling
@onready var game_camera: Camera2D = $Camera2D

# Debug mode flag - set to false to disable debug visualization
var debug_mode: bool = false
var debug_visualizer: Node2D = null

func _ready():
	# Connect to window resize signal to handle resolution changes
	get_tree().root.size_changed.connect(_on_window_resize)
	
	# Initial camera update
	update_camera()
	
	# Add debug visualizer if debug mode is enabled
	if debug_mode:
		add_debug_visualizer()

# Update all camera properties (position and zoom)
func update_camera():
	# Get tilemap boundaries
	var tilemap_rect = get_tilemap_rect()
	
	# Position camera at the center of the tilemap
	game_camera.position = tilemap_rect.get_center()
	
	# Get the viewport size
	var viewport_size = get_viewport_rect().size
	
	# Calculate the zoom factor to fit the tilemap in the viewport while maintaining aspect ratio
	var x_zoom = viewport_size.x / tilemap_rect.size.x
	var y_zoom = viewport_size.y / tilemap_rect.size.y
	
	# Use the smaller zoom factor to ensure the entire tilemap is visible
	var zoom_factor = min(x_zoom, y_zoom)
	
	# Apply zoom to the camera
	game_camera.zoom = Vector2(zoom_factor, zoom_factor)

# Calculates the rectangle that encompasses the entire tilemap
func get_tilemap_rect() -> Rect2:
	# Get used cells from both layers
	var ground_cells = ground_layer.get_used_cells()
	var obstacle_cells = obstacles_layer.get_used_cells()
	
	# Combine all cells
	var all_cells = ground_cells + obstacle_cells
	
	if all_cells.is_empty():
		return Rect2(0, 0, 800, 950)  # Default size if no tiles
	
	# Get tile size
	var tile_size = ground_layer.tile_set.tile_size
	
	# Find min and max coordinates
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for cell in all_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)
	
	# Calculate rect in world coordinates
	# Convert tile_size to Vector2 if it's not already
	var tile_size_vec = Vector2(tile_size.x, tile_size.y)
	
	var rect_pos = Vector2(min_x, min_y) * tile_size_vec
	var rect_size = Vector2(max_x - min_x + 1, max_y - min_y + 1) * tile_size_vec
	
	return Rect2(rect_pos, rect_size)

# Handles window resize events
func _on_window_resize():
	# Update all camera properties
	update_camera()

# Adds the debug visualizer to the scene
func add_debug_visualizer():
	# Create a new debug visualizer node
	debug_visualizer = Node2D.new()
	debug_visualizer.name = "DebugVisualizer"
	
	# Load and set the script
	var script = load("res://scripts/maze/debug_visualizer.gd")
	debug_visualizer.set_script(script)
	
	# Add to the scene
	add_child(debug_visualizer)

# Handle input for toggling debug visualization
func _input(event):
	# Toggle debug visualization with F1 key
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		toggle_debug_visualization()

# Toggle debug visualization on/off
func toggle_debug_visualization():
	debug_mode = !debug_mode
	
	if debug_mode and debug_visualizer == null:
		# Add debug visualizer if it doesn't exist
		add_debug_visualizer()
	elif !debug_mode and debug_visualizer != null:
		# Remove debug visualizer if it exists
		debug_visualizer.queue_free()
		debug_visualizer = null
