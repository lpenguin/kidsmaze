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

# Door is currently open
var is_open = false

func _ready():
	# Connect the area signals
	shape_cutout.body_entered.connect(_on_shape_entered)
	
	# Set up animations if they don't exist
	if not animation_player.has_animation("open"):
		_create_door_animations()

# Called when a physics body enters the door's cutout area
func _on_shape_entered(body):
	# Check if the body is a CharacterBody2D (part of the shape)
	if body.get_parent().is_in_group("shapes"):
		var shape = body.get_parent()
		
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

# Open the door when the correct shape enters
func open_door():
	# Play open animation
	if animation_player.has_animation("open"):
		animation_player.play("open")
	
	# Play sound
	if door_open_sound_path:
		var sound = load(door_open_sound_path)
		if sound:
			audio_player.stream = sound
			audio_player.play()
	
	# Disable the collision to let shapes pass through
	collision_shape.disabled = true
	is_open = true

# Reject shape that doesn't match the door type
func reject_shape(shape):
	# Play error sound
	if error_sound_path:
		var sound = load(error_sound_path)
		if sound:
			audio_player.stream = sound
			audio_player.play()
	
	# Play shake animation on the shape
	if shape.has_method("play_shake_animation"):
		shape.play_shake_animation()
	
	# Play shake animation on the door too
	if animation_player.has_animation("shake"):
		animation_player.play("shake")

# Reset the door to closed state
func close_door():
	if animation_player.has_animation("close"):
		animation_player.play("close")
	
	# Re-enable collision
	collision_shape.disabled = false
	is_open = false

# Create door animations and save them as resources
func _create_door_animations():
	# Create an AnimationLibrary resource to hold all animations
	var anim_library = AnimationLibrary.new()
	
	# 1. Create the open animation
	var open_anim = Animation.new()
	
	# Track for door transparency (fading)
	var track_idx = open_anim.add_track(Animation.TYPE_VALUE)
	open_anim.track_set_path(track_idx, "DoorSprite:modulate")
	open_anim.track_insert_key(track_idx, 0.0, Color(1, 1, 1, 1))    # Fully visible
	open_anim.track_insert_key(track_idx, 0.5, Color(1, 1, 1, 0.5))  # Half transparent
	
	# Track for collision shape disabling
	track_idx = open_anim.add_track(Animation.TYPE_VALUE)
	open_anim.track_set_path(track_idx, "StaticBody2D/CollisionShape2D:disabled")
	open_anim.track_insert_key(track_idx, 0.0, false)  # Collision enabled
	open_anim.track_insert_key(track_idx, 0.1, true)   # Collision disabled
	
	# Track for door scaling
	track_idx = open_anim.add_track(Animation.TYPE_VALUE)
	open_anim.track_set_path(track_idx, "DoorSprite:scale")
	open_anim.track_insert_key(track_idx, 0.0, Vector2(1.0, 1.0))   # Normal scale
	open_anim.track_insert_key(track_idx, 0.5, Vector2(0.8, 1.0))   # Squeeze horizontally
	
	open_anim.length = 0.5
	anim_library.add_animation("open", open_anim)
	
	# 2. Create the close animation
	var close_anim = Animation.new()
	
	# Track for door transparency (returning to solid)
	track_idx = close_anim.add_track(Animation.TYPE_VALUE)
	close_anim.track_set_path(track_idx, "DoorSprite:modulate")
	close_anim.track_insert_key(track_idx, 0.0, Color(1, 1, 1, 0.5))  # Half transparent
	close_anim.track_insert_key(track_idx, 0.5, Color(1, 1, 1, 1))    # Fully visible
	
	# Track for collision shape re-enabling
	track_idx = close_anim.add_track(Animation.TYPE_VALUE)
	close_anim.track_set_path(track_idx, "StaticBody2D/CollisionShape2D:disabled")
	close_anim.track_insert_key(track_idx, 0.4, true)    # Still disabled
	close_anim.track_insert_key(track_idx, 0.5, false)   # Collision re-enabled
	
	# Scale animation to match the open animation
	track_idx = close_anim.add_track(Animation.TYPE_VALUE)
	close_anim.track_set_path(track_idx, "DoorSprite:scale")
	close_anim.track_insert_key(track_idx, 0.0, Vector2(0.8, 1.0))   # Squeezed horizontally
	close_anim.track_insert_key(track_idx, 0.5, Vector2(1.0, 1.0))   # Normal scale
	
	close_anim.length = 0.5
	anim_library.add_animation("close", close_anim)
	
	# 3. Create the shake animation
	var shake_anim = Animation.new()
	
	# Track for door position shaking
	track_idx = shake_anim.add_track(Animation.TYPE_VALUE)
	shake_anim.track_set_path(track_idx, ".:position")
	shake_anim.track_insert_key(track_idx, 0.00, Vector2(0, 0))     # Center position
	shake_anim.track_insert_key(track_idx, 0.05, Vector2(-5, 0))    # Left
	shake_anim.track_insert_key(track_idx, 0.10, Vector2(5, 0))     # Right 
	shake_anim.track_insert_key(track_idx, 0.15, Vector2(-3, 0))    # Left (less)
	shake_anim.track_insert_key(track_idx, 0.20, Vector2(3, 0))     # Right (less)
	shake_anim.track_insert_key(track_idx, 0.25, Vector2(0, 0))     # Back to center
	
	shake_anim.length = 0.25
	anim_library.add_animation("shake", shake_anim)
	
	# Add the animation library to the animation player
	animation_player.add_animation_library("door_animations", anim_library)
	
	# Save the animation library to a resource file
	var err = ResourceSaver.save(anim_library, "res://resources/door_animations.res")
	if err == OK:
		print("Door animations saved successfully")
	else:
		print("Error saving door animations: " + str(err))
		
	# Load the saved animations instead of using the ones we just created
	# This ensures we're using the persisted animations
	var saved_lib = load("res://resources/door_animations.res")
	if saved_lib:
		animation_player.add_animation_library("door_animations", saved_lib)
	else:
		# If loading fails, continue using the ones we created in memory
		print("Could not load saved animations, using in-memory animations")