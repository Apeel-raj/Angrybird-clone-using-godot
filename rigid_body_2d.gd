extends RigidBody2D

var dragging = false
var start_pos = Vector2.ZERO

func _ready():
	# Save the starting position of the bird
	start_pos = global_position
	# Start the bird frozen in mid-air so it doesn't immediately fall
	freeze = true

func _input(event):
	# Check if player clicks the bird
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and global_position.distance_to(get_global_mouse_position()) < 50:
			dragging = true
		elif not event.pressed and dragging:
			dragging = false
			launch_bird()

func _process(_delta):
	# If dragging, move the bird with the mouse, but limit how far it can stretch
	if dragging:
		var mouse_pos = get_global_mouse_position()
		if start_pos.distance_to(mouse_pos) > 100:
			global_position = start_pos + (mouse_pos - start_pos).normalized() * 100
		else:
			global_position = mouse_pos

func launch_bird():
	# Unfreeze the physics engine so gravity takes over
	freeze = false
	# Calculate the launch direction (opposite of where you pulled back)
	var launch_vector = start_pos - global_position
	# Apply the force to fling the bird!
	apply_central_impulse(launch_vector * 10)
