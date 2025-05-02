extends Sprite2D

# Train car base script
# Handles shape placement validation for a specific car

signal shape_placed_correctly(car_node)
signal shape_removed(car_node)

# The type of shape that should go in this car
@export_enum("circle", "square", "triangle") var expected_shape_type: String
@export var correct_shape_sound: AudioStream
@export var incorrect_shape_sound: AudioStream

# Reference to the shape detection area
@onready var shape_area = $ShapeArea
@onready var audio_player = $AudioStreamPlayer2D

# Animation parameters
const BOUNCE_HEIGHT = 15.0
const BOUNCE_DURATION = 0.3
const WOBBLE_INTENSITY = 0.15
const SHAKE_INTENSITY = 5.0
const SHAKE_DURATION = 0.4
const SHAKE_FREQUENCY = 20.0

var current_shape = null
var has_correct_shape = false
var original_position = Vector2.ZERO
var animation_tween: Tween

func _ready():
	# Connect to the area signals
	shape_area.area_entered.connect(_on_shape_area_entered)
	shape_area.area_exited.connect(_on_shape_area_exited)
	
	# Store original position for animations
	original_position = position

func _on_shape_area_entered(area):
	# Check if this is a shape entering our area
	if area.get_parent().is_in_group("shapes"):
		var shape = area.get_parent()
		current_shape = shape
		
		# Check if it's the correct shape type
		if shape.shape_type.to_lower() == expected_shape_type:
			_on_correct_shape_placed(shape)
		else:
			_on_incorrect_shape_placed(shape)

func _on_shape_area_exited(area):
	# Check if a shape is leaving our area
	if area.get_parent().is_in_group("shapes") and current_shape != null:
		if has_correct_shape:
			has_correct_shape = false
			shape_removed.emit(self)
		
		current_shape = null

func _on_correct_shape_placed(shape):
	print("Correct shape placed: " + expected_shape_type)
	
	# Update state
	has_correct_shape = true
	
	# Play sound
	if audio_player and correct_shape_sound:
		audio_player.stream = correct_shape_sound
		audio_player.play()
	
	# Snap shape into position
	shape.global_position = shape_area.global_position
	
	# Disable shape dragging temporarily
	if shape.has_method("set_draggable"):
		shape.set_draggable(false)
	
	# Play the gummy bounce animation
	_play_correct_animation()
	
	# Emit signal
	shape_placed_correctly.emit(self)

func _on_incorrect_shape_placed(shape):
	print("Incorrect shape placed: " + shape.shape_type + ", expected: " + expected_shape_type)
	
	# Play error sound
	if audio_player and incorrect_shape_sound:
		audio_player.stream = incorrect_shape_sound
		audio_player.play()
		
	# Play the shake animation
	_play_incorrect_animation()

func _play_correct_animation():
	# Cancel any existing animation
	if animation_tween and animation_tween.is_valid():
		animation_tween.kill()
	
	# Create a new tween
	animation_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Store original scale and offset
	var original_scale = scale
	var original_offset = offset
	
	# First stretch upward (gummy effect)
	animation_tween.tween_property(self, "offset:y", offset.y - BOUNCE_HEIGHT, BOUNCE_DURATION * 0.5)
	animation_tween.parallel().tween_property(self, "scale:y", scale.y * (1.0 + WOBBLE_INTENSITY), BOUNCE_DURATION * 0.5)
	animation_tween.parallel().tween_property(self, "scale:x", scale.x * (1.0 - WOBBLE_INTENSITY * 0.5), BOUNCE_DURATION * 0.5)
	
	# Then bounce back
	animation_tween.tween_property(self, "offset:y", original_offset.y, BOUNCE_DURATION * 0.5)
	animation_tween.parallel().tween_property(self, "scale:y", original_scale.y, BOUNCE_DURATION * 0.5)
	animation_tween.parallel().tween_property(self, "scale:x", original_scale.x, BOUNCE_DURATION * 0.5)
	
	# Add a small wobble at the end
	animation_tween.tween_property(self, "scale:x", original_scale.x * (1.0 + WOBBLE_INTENSITY * 0.3), BOUNCE_DURATION * 0.3)
	animation_tween.tween_property(self, "scale:x", original_scale.x, BOUNCE_DURATION * 0.2)

func _play_incorrect_animation():
	# Cancel any existing animation
	if animation_tween and animation_tween.is_valid():
		animation_tween.kill()
	
	# Create a new tween
	animation_tween = create_tween().set_trans(Tween.TRANS_SINE)
	
	# Store original offset
	var original_offset = offset
	
	# Number of shakes
	var shake_count = int(SHAKE_DURATION * SHAKE_FREQUENCY)
	
	# Add random shaking motion
	for i in range(shake_count):
		var shake_offset = Vector2(
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		)
		animation_tween.tween_property(self, "offset", original_offset + shake_offset, 1.0 / SHAKE_FREQUENCY)
	
	# Return to original position
	animation_tween.tween_property(self, "offset", original_offset, 0.1)
