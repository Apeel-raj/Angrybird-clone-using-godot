extends Node2D

signal bird_launched(bird_node)

@export var max_drag_distance: float = 120.0
@export var launch_force_multiplier: float = 8.5
@export var trajectory_point_count: int = 40
@export var trajectory_time_step: float = 0.045

@onready var left_anchor: Marker2D = $LeftAnchor
@onready var right_anchor: Marker2D = $RightAnchor
@onready var center_marker: Marker2D = $CenterMarker
@onready var left_band: Line2D = $LeftBand
@onready var right_band: Line2D = $RightBand
@onready var trajectory_line: Line2D = $TrajectoryLine

var bird: RigidBody2D = null
var dragging: bool = false
var center_position: Vector2 = Vector2.ZERO
var last_stretch_sound_pos: float = 0.0

func _ready():
	# Set center position from marker or calculate
	if center_marker:
		center_position = center_marker.global_position
	else:
		center_position = (left_anchor.global_position + right_anchor.global_position) / 2.0
		
	# Initialize bands
	reset_bands()
	
	if trajectory_line:
		trajectory_line.visible = false
		trajectory_line.clear_points()
		trajectory_line.top_level = true

func load_bird(new_bird: RigidBody2D):
	if bird and is_instance_valid(bird) and bird != new_bird:
		bird.queue_free()
	bird = new_bird
	bird.global_position = center_position
	bird.freeze = true
	bird.linear_velocity = Vector2.ZERO
	bird.angular_velocity = 0.0
	bird.rotation = 0.0
	dragging = false
	reset_bands()

func reset_bands():
	if left_band and left_anchor:
		left_band.points = [left_band.to_local(left_anchor.global_position), left_band.to_local(center_position)]
		left_band.visible = true
	if right_band and right_anchor:
		right_band.points = [right_band.to_local(right_anchor.global_position), right_band.to_local(center_position)]
		right_band.visible = true
	if trajectory_line:
		trajectory_line.visible = false

func update_bands(target_pos: Vector2):
	if left_band and left_anchor:
		left_band.points = [left_band.to_local(left_anchor.global_position), left_band.to_local(target_pos)]
	if right_band and right_anchor:
		right_band.points = [right_band.to_local(right_anchor.global_position), right_band.to_local(target_pos)]

func _input(event):
	if bird == null:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = get_global_mouse_position()
			# Start dragging if click is close to bird or slingshot center
			if mouse_pos.distance_to(bird.global_position) < 70.0 or mouse_pos.distance_to(center_position) < 70.0:
				dragging = true
				bird.freeze = true
		elif not event.pressed and dragging:
			dragging = false
			launch_loaded_bird()

func _process(_delta):
	if dragging and bird:
		var mouse_pos = get_global_mouse_position()
		var drag_vector = mouse_pos - center_position
		
		# Limit the drag distance
		if drag_vector.length() > max_drag_distance:
			drag_vector = drag_vector.normalized() * max_drag_distance
			
		var target_pos = center_position + drag_vector
		
		# Clamp to prevent ground penetration (top of ground is y=568)
		var bird_radius = 22.0
		if bird.has_node("CollisionShape2D"):
			var shape_node = bird.get_node("CollisionShape2D")
			if shape_node and shape_node.shape is CircleShape2D:
				bird_radius = shape_node.shape.radius
		var max_y = 568.0 - bird_radius - 4.0 # 4px clearance
		target_pos.y = min(target_pos.y, max_y)
		
		# Recalculate drag vector based on clamped target_pos
		drag_vector = target_pos - center_position
		
		bird.global_position = target_pos
		
		# Play stretch click sound periodically as they drag
		var current_dist = drag_vector.length()
		if abs(current_dist - last_stretch_sound_pos) > 15.0:
			last_stretch_sound_pos = current_dist
			var scene = get_tree().current_scene
			if scene and scene.has_method("play_sound"):
				scene.play_sound("stretch")
		
		# Update bands and path prediction
		update_bands(bird.global_position)
		update_trajectory(drag_vector)

func update_trajectory(drag_vector: Vector2):
	if not trajectory_line:
		return
		
	trajectory_line.visible = true
	var points = []
	var start_pos = bird.global_position
	# Launch velocity is opposite to drag direction
	var velocity = -drag_vector * launch_force_multiplier
	var gravity = Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	
	var pos = start_pos
	var temp_vel = velocity
	for i in range(trajectory_point_count):
		points.append(trajectory_line.to_local(pos))
		pos += temp_vel * trajectory_time_step
		temp_vel += gravity * trajectory_time_step
		
	trajectory_line.points = points

func launch_loaded_bird():
	if not bird:
		return
		
	var drag_vector = bird.global_position - center_position
	
	# Cancel launch and snap back if dragged less than 15 pixels
	if drag_vector.length() < 15.0:
		dragging = false
		var cancel_tween = create_tween()
		cancel_tween.tween_property(bird, "global_position", center_position, 0.15)
		cancel_tween.finished.connect(reset_bands)
		return
		
	var launch_velocity = -drag_vector * launch_force_multiplier
	
	if trajectory_line:
		trajectory_line.visible = false
		
	var launched_bird = bird
	bird = null
	
	# Elastic band snap back animation
	var snap_start = launched_bird.global_position
	var tween = create_tween()
	tween.tween_method(func(t: float):
		var current_pos = snap_start.lerp(center_position, t)
		update_bands(current_pos)
	, 0.0, 1.0, 0.08) # snap back in 80ms
	
	# Play launch sound
	var scene = get_tree().current_scene
	if scene and scene.has_method("play_sound"):
		scene.play_sound("launch")
		
	launched_bird.launch(launch_velocity)
	emit_signal("bird_launched", launched_bird)
