extends Sprite2D
class_name TrainCar

# Train car base script
# Handles shape placement validation for a specific car

signal shape_placed_correctly(car_node)
signal shape_removed(car_node)

# The type of shape that should go in this car
@export_enum("circle", "square", "triangle") var expected_shape_type: String
@export var correct_shape_sound: AudioStream
@export var incorrect_shape_sound: AudioStream
var has_correct_shape := false

# Reference to the shape detection area
@onready var _shape_area: Area2D = $ShapeArea
@onready var _audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Animation parameters
const BOUNCE_HEIGHT := 15.0
const BOUNCE_DURATION := 0.3
const WOBBLE_INTENSITY := 0.15
const SHAKE_INTENSITY := 5.0
const SHAKE_DURATION := 0.4
const SHAKE_FREQUENCY := 20.0

var _current_shape: Shape = null
var _original_position := Vector2.ZERO
var _animation_tween: Tween
var _shape_entry_position := Vector2.ZERO

func _ready() -> void:
	# Connect to the area signals
	_shape_area.body_entered.connect(_on_shape_body_entered)
	_shape_area.body_exited.connect(_on_shape_body_exited)
	
	# Store original position for animations
	_original_position = position

func _on_shape_body_entered(body: Node2D) -> void:
	# Check if this is a shape entering our area
	if body.is_in_group("shapes"):
		var shape := body as Shape
		_current_shape = shape
		_shape_entry_position = shape.global_position

func _on_shape_body_exited(body: Node2D) -> void:
	# Check if a shape is leaving our area
	if body.is_in_group("shapes") and _current_shape == body:	
		_current_shape = null
		_shape_entry_position = Vector2.ZERO

# Get the expected shape type for this car
func get_shape_type() -> String:
	return expected_shape_type

# Handles the behavior when a correct shape is placed in the car
func handle_correct_shape_placement(shape: Shape) -> void:
	# Move shape to center of train car
	shape.move_to_position(_shape_area.global_position)
	
	# Wait for the movement to complete
	await shape.auto_movement_completed
	
	# Hide the shape
	shape.visible = false
	
	# Mark this car as having the correct shape
	has_correct_shape = true
	shape_placed_correctly.emit(self)
	
	# Play the correct animation on the train car
	_play_correct_animation()
	
	# Play sound
	if _audio_player and correct_shape_sound:
		_audio_player.stream = correct_shape_sound
		_audio_player.play()

# Handles the behavior when an incorrect shape is placed in the car
func handle_incorrect_shape_placement(shape: Shape) -> void:
	# Get entry position or use current position if not available
	var entry_position := _shape_entry_position
	
	# Calculate "last position" - outside the car with a small offset
	var direction := (shape.global_position - global_position).normalized()
	var target_pos := entry_position + direction * 1.0  # Adding offset to not touch

	# Move shape to the "last position"
	shape.move_to_position(target_pos)
	
	# Wait for the movement to complete
	await shape.auto_movement_completed
	
	# Restore player control
	shape.restore_player_control()
	
	# Play the incorrect animation on the train car
	_play_incorrect_animation()
	
	# Play sound
	if _audio_player and incorrect_shape_sound:
		_audio_player.stream = incorrect_shape_sound
		_audio_player.play()

func _play_correct_animation() -> void:
	# Cancel any existing animation
	if _animation_tween and _animation_tween.is_valid():
		_animation_tween.kill()
	
	# Create a new tween
	_animation_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Store original scale and offset
	var original_scale := scale
	var original_offset := offset
	
	# First stretch upward (gummy effect)
	_animation_tween.tween_property(self, "offset:y", offset.y - BOUNCE_HEIGHT, BOUNCE_DURATION * 0.5)
	_animation_tween.parallel().tween_property(self, "scale:y", scale.y * (1.0 + WOBBLE_INTENSITY), BOUNCE_DURATION * 0.5)
	_animation_tween.parallel().tween_property(self, "scale:x", scale.x * (1.0 - WOBBLE_INTENSITY * 0.5), BOUNCE_DURATION * 0.5)
	
	# Then bounce back
	_animation_tween.tween_property(self, "offset:y", original_offset.y, BOUNCE_DURATION * 0.5)
	_animation_tween.parallel().tween_property(self, "scale:y", original_scale.y, BOUNCE_DURATION * 0.5)
	_animation_tween.parallel().tween_property(self, "scale:x", original_scale.x, BOUNCE_DURATION * 0.5)
	
	# Add a small wobble at the end
	_animation_tween.tween_property(self, "scale:x", original_scale.x * (1.0 + WOBBLE_INTENSITY * 0.3), BOUNCE_DURATION * 0.3)
	_animation_tween.tween_property(self, "scale:x", original_scale.x, BOUNCE_DURATION * 0.2)

func _play_incorrect_animation() -> void:
	# Cancel any existing animation
	if _animation_tween and _animation_tween.is_valid():
		_animation_tween.kill()
	
	# Create a new tween
	_animation_tween = create_tween().set_trans(Tween.TRANS_SINE)
	
	# Store original offset
	var original_offset := offset
	
	# Number of shakes
	var shake_count := int(SHAKE_DURATION * SHAKE_FREQUENCY)
	
	# Add random shaking motion
	for i in range(shake_count):
		var shake_offset := Vector2(
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		)
		_animation_tween.tween_property(self, "offset", original_offset + shake_offset, 1.0 / SHAKE_FREQUENCY)
	
	# Return to original position
	_animation_tween.tween_property(self, "offset", original_offset, 0.1)
