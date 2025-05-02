# scripts/maze/debug_visualizer.gd
extends Node2D

# Reference to the maze script
@onready var maze = get_parent()

# Debug drawing colors
var tilemap_boundary_color = Color(1, 0, 0, 0.5)  # Red with transparency
var viewport_boundary_color = Color(0, 1, 0, 0.5)  # Green with transparency

# Debug drawing enabled flag
var debug_drawing_enabled = true

func _ready():
	# Set process to handle drawing
	set_process(debug_drawing_enabled)

func _process(_delta):
	# Force redraw
	queue_redraw()

func _draw():
	if not debug_drawing_enabled:
		return
		
	# Draw tilemap boundaries
	var tilemap_rect = maze.get_tilemap_rect()
	draw_rect(tilemap_rect, tilemap_boundary_color, false, 2.0)
	
	# Draw viewport boundaries in world space
	var viewport_rect = get_viewport_rect()
	var camera_zoom = maze.game_camera.zoom
	var camera_pos = maze.game_camera.position
	
	# Calculate viewport rect in world space
	var half_size = viewport_rect.size / (2.0 * camera_zoom)
	var world_viewport_rect = Rect2(
		camera_pos - half_size,
		viewport_rect.size / camera_zoom
	)
	
	# Draw viewport boundaries
	draw_rect(world_viewport_rect, viewport_boundary_color, false, 2.0)
	
	# Draw center points
	draw_circle(tilemap_rect.get_center(), 5, Color.RED)
	draw_circle(camera_pos, 5, Color.GREEN)
