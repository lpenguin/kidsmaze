extends Node2D

# Train controller script
# Manages the entire train and validates when all shapes are correctly placed

signal train_completed

# References to the cars
var cars = []
var all_shapes_correct = false

func _ready():
	# Get references to all car nodes
	cars = [$CircleCar, $SquareCar, $TriangleCar]
	
	# Connect signals from all cars
	for car in cars:
		car.shape_placed_correctly.connect(_on_shape_placed_correctly)
		car.shape_removed.connect(_on_shape_removed)
	
	# Initial check
	_check_train_completion()

func _on_shape_placed_correctly(car_node):
	print("Shape placed correctly in " + car_node.name)
	_check_train_completion()

func _on_shape_removed(car_node):
	print("Shape removed from " + car_node.name)
	all_shapes_correct = false

func _check_train_completion():
	# Check if all cars have their correct shapes
	all_shapes_correct = true
	
	for car in cars:
		if not car.has_correct_shape:
			all_shapes_correct = false
			break
	
	if all_shapes_correct:
		print("All shapes correctly placed!")
		train_completed.emit()
		_play_completion_animation()

func _play_completion_animation():
	# Animate the train when all shapes are correctly placed
	var tween = create_tween()
	tween.tween_property(self, "position:x", position.x + 1000, 3.0)
	tween.tween_callback(_on_train_departed)

func _on_train_departed():
	# Hide the train after it has left the screen
	visible = false