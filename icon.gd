extends Sprite2D

# This is the speed of our robot in pixels per second
@export var speed: float = 400.0

# This function runs every single frame of the game
func _process(delta: float) -> void:
	var velocity = Vector2.ZERO # Start with no movement

	# Check for keyboard inputs
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		velocity.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		velocity.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		velocity.y -= 1

	# If we are moving, make sure we move at the right speed
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	# Update the robot's position
	position += velocity * delta
