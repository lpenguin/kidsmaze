extends CharacterBody2D

class_name Shape

# Shape properties
var _dragging := false
var _drag_offset := Vector2.ZERO
var _current_input_position := Vector2.ZERO  # Store the current input position (mouse or touch)
@export var shape_type: String = "base"  # Set this directly in each child scene
@export var movement_speed: float = 10.0  # Default movement speed multiplier
var _can_move := true

# Sound effect paths (to be set in the editor)
@export var pickup_sound_path: String = ""
@export var drop_sound_path: String = ""
@export var collision_sound_path: String = ""

# Original position to return to if needed
var _start_position := Vector2.ZERO

# Auto-movement properties
var _auto_moving := false
var _target_destination := Vector2.ZERO
var _auto_move_speed := 15.0
var _auto_move_completion_distance := 5.0

# Node references
@onready var area_2d: Area2D = $Area2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Signal for auto movement completion
signal auto_movement_completed

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	_start_position = global_position
	# Make sure input processing is enabled
	set_process_input(true)

# Convert screen coordinates to global coordinates
func _convert_to_global_position(screen_position: Vector2) -> Vector2:
	# If the position is empty, use the current mouse position
	if screen_position.is_zero_approx():
		return get_global_mouse_position()
	
	# Convert screen position to global position
	return get_canvas_transform().affine_inverse() * screen_position

# Handle input events
func _input(event: InputEvent) -> void:
	if not _can_move:
		return
	
	# Common variables for both mouse and touch
	var is_pressed := false
	var input_position := Vector2.ZERO
	
	# Extract common properties based on event type
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = event.pressed
		input_position = event.position
	elif event is InputEventScreenTouch:
		is_pressed = event.pressed
		input_position = event.position
	elif event is InputEventMouseMotion and _dragging:
		# Update current position for mouse movement during drag
		_current_input_position = get_global_mouse_position()
		return
	elif event is InputEventScreenDrag and _dragging:
		# Update current position for touch drag events
		_current_input_position = _convert_to_global_position(event.position)
		return
	else:
		# Not a relevant event
		return
	
	# Convert screen position to global position
	var global_input_position := _convert_to_global_position(input_position)
	_current_input_position = global_input_position
	
	# Handle press/release with common code
	if is_pressed:
		if _is_point_over_shape(global_input_position):
			start_drag(global_input_position)
	elif _dragging:
		stop_drag()

# Check if a point is over this shape
func _is_point_over_shape(point_position: Vector2) -> bool:
	var collision_shape := $TouchCollisionShape2D as CollisionShape2D
	
	# For circle shapes
	if collision_shape.shape is CircleShape2D:
		var radius := (collision_shape.shape as CircleShape2D).radius
		var distance := global_position.distance_to(point_position)
		return distance < radius
	
	# Default fallback for other shapes (could be improved)
	return false

# Called every physics frame
func _physics_process(delta: float) -> void:
	var movement := Vector2.ZERO
	var move_speed := movement_speed
	
	# Update current mouse position if dragging with mouse
	if _dragging:
		# For mouse dragging, always get the latest mouse position
		_current_input_position = get_global_mouse_position()
	
	if _auto_moving:
		# Calculate movement vector toward target_destination
		movement = _target_destination - global_position
		
		# Check if we've reached the destination
		if movement.length() < _auto_move_completion_distance:
			_auto_moving = false
			emit_signal("auto_movement_completed")
			return
		move_speed = _auto_move_speed
	elif _dragging:
		# Calculate target position based on current input position
		var target_position := _current_input_position - _drag_offset
		
		# Calculate movement vector
		movement = target_position - global_position
	
	# If we have movement to apply (either from dragging or auto-moving)
	if movement != Vector2.ZERO:
		# Attempt to move with the movement vector
		var collision := move_and_collide(movement * delta * move_speed)
		
		# If there's a collision, try to slide along the wall
		if collision:
			# Get the normal of the collision surface
			var normal := collision.get_normal()
			
			# Calculate the slide vector (projection of movement onto the wall)
			var slide_movement := movement - (movement.dot(normal) * normal)
			
			# Try to slide along the wall
			move_and_collide(slide_movement * delta * move_speed)
			
			# Play collision sound (only during dragging)
			if _dragging and collision_sound_path and audio_player:
				var sound := load(collision_sound_path) as AudioStream
				if sound:
					audio_player.stream = sound
					audio_player.play()

func start_drag(from_position: Vector2 = Vector2.ZERO) -> void:
	_dragging = true
	
	# If no position provided, use current input position
	if from_position.is_zero_approx():
		_drag_offset = _current_input_position - global_position
	else:
		_drag_offset = from_position - global_position
	
	# Visual feedback for dragging
	scale = Vector2(1.1, 1.1)  # Slightly enlarge shape
	
	# Play pickup sound
	if pickup_sound_path and audio_player:
		var sound := load(pickup_sound_path) as AudioStream
		if sound:
			audio_player.stream = sound
			audio_player.play()

func stop_drag() -> void:
	_dragging = false
	scale = Vector2(1.0, 1.0)  # Reset scale
	
	# Play drop sound
	if drop_sound_path and audio_player:
		var sound := load(drop_sound_path) as AudioStream
		if sound:
			audio_player.stream = sound
			audio_player.play()
	
	# Check for train cars that this shape might be dropped on
	var train_car := _check_for_train_car()
	if train_car:
		# Let the train car handle the shape
		if train_car.get_shape_type() == shape_type:
			train_car.handle_correct_shape_placement(self)
		else:
			train_car.handle_incorrect_shape_placement(self)

# Check if the shape is dropped on a train car
func _check_for_train_car() -> TrainCar:
	if not area_2d:
		return null

	var overlapping_areas := area_2d.get_overlapping_areas()
	var found_car: TrainCar = null
	for area in overlapping_areas:
		if area.get_parent() is TrainCar:
			if not found_car or found_car.get_shape_type() != shape_type:
				found_car = area.get_parent() as TrainCar
	
	return found_car

# Play shake animation to indicate a wrong placement
func play_shake_animation() -> void:
	# Create a simple shake animation using a Tween
	var tween := create_tween()
	var start_pos := position
	
	# Series of quick left-right movements
	tween.tween_property(self, "position", start_pos + Vector2(-5, 0), 0.05)
	tween.tween_property(self, "position", start_pos + Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", start_pos + Vector2(-5, 0), 0.05)
	tween.tween_property(self, "position", start_pos + Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", start_pos, 0.05)
	
	# Play error sound if available
	if collision_sound_path and audio_player:
		var sound := load(collision_sound_path) as AudioStream
		if sound:
			audio_player.stream = sound
			audio_player.play()

# Get the shape type (used by doors and train cars)
func get_shape_type() -> String:
	return shape_type

# Reset shape to its starting position
func reset_position() -> void:
	global_position = _start_position
	
# Disable movement (e.g., after successful placement)
func disable_movement() -> void:
	_can_move = false
	
# Enable movement
func enable_movement() -> void:
	_can_move = true

# Move the shape to a target destination with automatic movement
func move_to_position(position: Vector2) -> void:
	# Stop dragging if we were dragging
	if _dragging:
		_dragging = false
		scale = Vector2(1.0, 1.0)  # Reset scale
	
	# Setup auto movement
	_target_destination = position
	_auto_moving = true
	_can_move = false  # Disable player control during auto movement

# Enable movement after auto-movement completes
func restore_player_control() -> void:
	_can_move = true
