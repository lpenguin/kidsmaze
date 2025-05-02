extends Node2D

class_name Shape

# Shape properties
var dragging = false
var drag_offset = Vector2()
@export var shape_type: String = "base"  # Set this directly in each child scene
@export var movement_speed: float = 10.0  # Default movement speed multiplier
var can_move = true

# Sound effect paths (to be set in the editor)
@export var pickup_sound_path: String = ""
@export var drop_sound_path: String = ""
@export var collision_sound_path: String = ""

# Original position to return to if needed
var start_position = Vector2()

# Called when the node enters the scene tree for the first time
func _ready():
	start_position = global_position
	# Make sure input processing is enabled
	set_process_input(true)

# Handle input events
func _input(event):
	if not can_move:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if the mouse is over this shape
			if _is_mouse_over_shape():
				start_drag(event.global_position)
		elif dragging:
			stop_drag()

# Check if mouse is over this shape
func _is_mouse_over_shape():
	# Get the mouse position
	var mouse_pos = get_global_mouse_position()
	
	# Get the CharacterBody2D node
	var body = $CharacterBody2D
	
	# Get the collision shape's global position and extents
	var shape_pos = body.global_position
	var collision_shape = body.get_node("CollisionShape2D").shape
	
	# For circle shapes
	if collision_shape is CircleShape2D:
		var radius = collision_shape.radius
		var distance = shape_pos.distance_to(mouse_pos)
		return distance < radius
	
	# Default fallback for other shapes (could be improved)
	return false

# Called every physics frame
func _physics_process(delta):
	if dragging:
		# Calculate target position based on mouse
		var target_position = get_global_mouse_position() - drag_offset
		
		# Calculate movement vector
		var movement = target_position - $CharacterBody2D.global_position
		
		# Attempt to move with the initial movement vector
		var collision = $CharacterBody2D.move_and_collide(movement * delta * movement_speed)
		
		# If there's a collision, try to slide along the wall
		if collision:
			# Get the normal of the collision surface
			var normal = collision.get_normal()
			
			# Calculate the slide vector (projection of movement onto the wall)
			var slide_movement = movement - (movement.dot(normal) * normal)
			
			# Try to slide along the wall
			var slide_collision = $CharacterBody2D.move_and_collide(slide_movement * delta * movement_speed)
			
			# If there's a collision during sliding (e.g., in a corner), stop movement
			# No need for additional feedback as requested
			
			# Play collision sound (only for the first collision)
			if collision_sound_path and $AudioStreamPlayer2D:
				var sound = load(collision_sound_path)
				if sound:
					$AudioStreamPlayer2D.stream = sound
					$AudioStreamPlayer2D.play()

func start_drag(mouse_pos):
	dragging = true
	drag_offset = mouse_pos - $CharacterBody2D.global_position
	
	# Visual feedback for dragging
	$CharacterBody2D.scale = Vector2(1.1, 1.1)  # Slightly enlarge shape
	
	# Play pickup sound
	if pickup_sound_path and $AudioStreamPlayer2D:
		var sound = load(pickup_sound_path)
		if sound:
			$AudioStreamPlayer2D.stream = sound
			$AudioStreamPlayer2D.play()

func stop_drag():
	dragging = false
	$CharacterBody2D.scale = Vector2(1.0, 1.0)  # Reset scale
	
	# Play drop sound
	if drop_sound_path and $AudioStreamPlayer2D:
		var sound = load(drop_sound_path)
		if sound:
			$AudioStreamPlayer2D.stream = sound
			$AudioStreamPlayer2D.play()
	
	# Check for special placement logic (to be implemented for doors and train cars)
	_check_placement()

# Check if the shape is properly placed (doors, train cars)
func _check_placement():
	# Look for door areas that this shape might be overlapping with
	var overlapping_areas = []
	var areas = $CharacterBody2D/Area2D.get_overlapping_areas()
	
	for area in areas:
		# Check if it's a door cutout area
		if area.get_parent().has_method("_on_shape_entered"):
			# Don't need to do anything here, as the door will handle the interaction
			# through its _on_shape_entered method
			pass
	
	# Future: Add check for train car placement

# Play shake animation to indicate a wrong placement
func play_shake_animation():
	# Create a simple shake animation using a Tween
	var tween = create_tween()
	var start_pos = $CharacterBody2D.position
	
	# Series of quick left-right movements
	tween.tween_property($CharacterBody2D, "position", start_pos + Vector2(-5, 0), 0.05)
	tween.tween_property($CharacterBody2D, "position", start_pos + Vector2(5, 0), 0.05)
	tween.tween_property($CharacterBody2D, "position", start_pos + Vector2(-5, 0), 0.05)
	tween.tween_property($CharacterBody2D, "position", start_pos + Vector2(5, 0), 0.05)
	tween.tween_property($CharacterBody2D, "position", start_pos, 0.05)
	
	# Play error sound if available
	if collision_sound_path and $AudioStreamPlayer2D:
		var sound = load(collision_sound_path)
		if sound:
			$AudioStreamPlayer2D.stream = sound
			$AudioStreamPlayer2D.play()

# Get the shape type (used by doors and train cars)
func get_shape_type():
	return shape_type

# Reset shape to its starting position
func reset_position():
	global_position = start_position
	$CharacterBody2D.global_position = global_position
	
# Disable movement (e.g., after successful placement)
func disable_movement():
	can_move = false
	
# Enable movement
func enable_movement():
	can_move = true