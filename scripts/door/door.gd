extends Node2D

# Door.gd - Script for handling door interactions with shapes

# Signal when a shape enters the door successfully
signal shape_entered
# Signal when a shape tries to enter but doesn't match
signal wrong_shape_tried

# Door type (one of: "circle", "square", "triangle")
@export var door_type: String = "circle"

# References to nodes
@onready var shape_cutout = $ShapeCutout
@onready var collision_shape = $StaticBody2D/CollisionShape2D
@onready var door_sprite = $DoorSprite
@onready var audio_player = $AudioStreamPlayer2D
@onready var animation_player = $AnimationPlayer

# Sound effect paths
@export var success_sound_path: String = ""
@export var error_sound_path: String = ""
@export var door_open_sound_path: String = ""

const ANIMATION_OPEN = "door_animations/open"
const ANIMATION_CLOSE = "door_animations/close"
const ANIMATION_SHAKE = "door_animations/shake"

# Door is currently open
var is_open = false

func _ready():
	# Connect the area signals
	shape_cutout.body_entered.connect(_on_shape_entered)
	shape_cutout.body_exited.connect(_on_shape_exited)

# Called when a physics body enters the door's cutout area
func _on_shape_entered(body):
	# Check if the body is a CharacterBody2D (part of the shape)
	if body.is_in_group("shapes"):
		var shape = body
		
		# If door is already open, let the shape pass through
		if is_open:
			return
			
		# Check if the shape type matches the door type
		if shape.shape_type == door_type:
			open_door()
			shape_entered.emit()
		else:
			reject_shape(shape)
			wrong_shape_tried.emit()

# Called when a physics body exits the door's cutout area
func _on_shape_exited(body):
	# Check if the body is a CharacterBody2D (part of the shape)
	if body.is_in_group("shapes") and is_open:
		close_door()

# Open the door when the correct shape enters
func open_door():
	# Play open animation
	if animation_player.has_animation(ANIMATION_OPEN):
		animation_player.play(ANIMATION_OPEN)
	
	# Play sound
	if door_open_sound_path:
		var sound = load(door_open_sound_path)
		if sound:
			audio_player.stream = sound
			audio_player.play()
	
	# Disable the collision to let shapes pass through - use call_deferred to avoid physics errors
	_disable_collision.call_deferred()
	is_open = true

# Helper function to safely disable collision
func _disable_collision():
	collision_shape.disabled = true

# Reject shape that doesn't match the door type
func reject_shape(shape):
	# Play error sound
	if error_sound_path:
		var sound = load(error_sound_path)
		if sound:
			audio_player.stream = sound
			audio_player.play()
	
	# Play shake animation on the door too
	if animation_player.has_animation(ANIMATION_SHAKE):
		animation_player.play(ANIMATION_SHAKE)

# Reset the door to closed state
func close_door():
	if animation_player.has_animation(ANIMATION_CLOSE):
		animation_player.play(ANIMATION_CLOSE)
	
	# Re-enable collision - use call_deferred to avoid physics errors
	_enable_collision.call_deferred()
	is_open = false

# Helper function to safely enable collision
func _enable_collision():
	collision_shape.disabled = false
