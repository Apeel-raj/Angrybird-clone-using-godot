extends RigidBody2D

signal launched
signal destroyed

enum BirdType { RED, YELLOW, BOMB, BLUE }

@export var type: BirdType = BirdType.RED
@export var max_trail_points: int = 35
@export var trail_min_distance: float = 6.0
@export var fade_duration: float = 0.8

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trail_line: Line2D = $TrailLine

var was_launched: bool = false
var has_hit: bool = false
var power_activated: bool = false
var flight_time: float = 0.0
var last_trail_pos: Vector2 = Vector2.ZERO
var trigger_explosion_flag: bool = false
var is_being_destroyed: bool = false

func _ready():
	# Save start position for the trail
	last_trail_pos = global_position
	
	add_to_group("birds")
	
	# Enable contact monitoring for body_entered signals
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	
	# Configure bird based on type
	setup_bird_type()
	
	if trail_line:
		trail_line.clear_points()
		trail_line.top_level = true

func setup_bird_type():
	# Duplicate the collision shape so instances don't share shape resource changes
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
		
	var texture_path = "res://bird.svg"
	var scale_factor = 0.35
	var mass_val = 1.0
	var trail_color = Color(1.0, 1.0, 1.0, 0.4)
	
	match type:
		BirdType.RED:
			texture_path = "res://bird.svg"
			scale_factor = 0.35
			mass_val = 1.0
			trail_color = Color(1.0, 1.0, 1.0, 0.45)
		BirdType.YELLOW:
			texture_path = "res://bird_yellow.svg"
			scale_factor = 0.35
			mass_val = 0.85
			trail_color = Color(1.0, 0.85, 0.2, 0.5)
		BirdType.BOMB:
			texture_path = "res://bird_bomb.svg"
			scale_factor = 0.45 # Bomb is larger!
			mass_val = 2.2      # Bomb is heavier!
			trail_color = Color(0.25, 0.25, 0.25, 0.5)
		BirdType.BLUE:
			texture_path = "res://bird_blue.svg"
			scale_factor = 0.22 # Blue is small!
			mass_val = 0.5      # Blue is light!
			trail_color = Color(0.4, 0.8, 1.0, 0.5)
			
	# Apply configuration
	if sprite:
		sprite.texture = load(texture_path)
		sprite.scale = Vector2(scale_factor, scale_factor)
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = 22.0 * (scale_factor / 0.35)
	mass = mass_val
	if trail_line:
		trail_line.default_color = trail_color
		trail_line.width = 6.0 * (scale_factor / 0.35)

func launch(velocity_vector: Vector2):
	freeze = false
	sleeping = false
	linear_velocity = velocity_vector
	was_launched = true
	
	# Defer changes to handle Godot 4 initialization timing robustly
	set_deferred("freeze", false)
	set_deferred("sleeping", false)
	set_deferred("linear_velocity", velocity_vector)
	
	emit_signal("launched")

func _input(event):
	# Listen for tap/click in mid-flight to activate special powers
	if was_launched and not has_hit and not power_activated:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			activate_power()

func activate_power():
	power_activated = true
	var scene = get_tree().current_scene
	if scene and scene.has_method("play_sound"):
		scene.play_sound("power")
	match type:
		BirdType.YELLOW:
			# Speed boost: increase current velocity in forward direction by 1.8x
			linear_velocity = linear_velocity.normalized() * (linear_velocity.length() * 1.8)
			# Spawn quick flash trail
			if trail_line:
				trail_line.width *= 1.8
		BirdType.BLUE:
			# Split: spawn two clone birds at positive/negative 15 degree offsets
			split_blue_bird()
		BirdType.BOMB:
			# Explosion: trigger detonation on next physics step
			trigger_explosion_flag = true

func split_blue_bird():
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var speed = linear_velocity.length()
	# Guard: don't split if the bird is stuck or has zero velocity
	if speed < 100.0:
		return
		
	var angle = linear_velocity.angle()
	
	# Spawn top and bottom clones
	spawn_clone(angle + 0.26, speed, parent_node)  # ~15 degrees up
	spawn_clone(angle - 0.26, speed, parent_node)  # ~15 degrees down

func spawn_clone(target_angle: float, speed: float, parent_node: Node):
	var bird_scene = load("res://bird.tscn")
	var clone = bird_scene.instantiate()
	clone.type = BirdType.BLUE
	clone.global_position = global_position
	parent_node.add_child(clone)
	
	# Set power_activated to true so clones cannot split recursively
	clone.power_activated = true
	
	# Calculate new trajectory velocity vector
	var new_vel = Vector2.from_angle(target_angle) * speed
	clone.launch(new_vel)
	
	# Register the clone in the main scene's birds_in_flight array
	if parent_node.has_method("register_bird_in_flight"):
		parent_node.register_bird_in_flight(clone)

func _physics_process(delta):
	# Perform bomb explosion in physics thread to prevent race conditions
	if trigger_explosion_flag:
		trigger_explosion_flag = false
		explode()
		return

	if was_launched and not freeze:
		flight_time += delta
		
		# Draw the trail behind the bird
		if trail_line and not has_hit:
			var current_pos = global_position
			if current_pos.distance_to(last_trail_pos) > trail_min_distance:
				trail_line.add_point(current_pos)
				last_trail_pos = current_pos
				if trail_line.get_point_count() > max_trail_points:
					trail_line.remove_point(0)
		
		# Auto-destroy if it goes way out of bounds
		if global_position.y > 1000 or global_position.x > 2000 or global_position.x < -500:
			destroy_bird()
		
		# Auto-destroy if it's been flying for a while and stops moving
		if flight_time > 4.5 and linear_velocity.length() < 12.0:
			destroy_bird()

func _on_body_entered(_body):
	# Upon first collision, trigger powers for Bomb, or start fade timer for others
	if was_launched and not has_hit:
		has_hit = true
		if type == BirdType.BOMB:
			# Bomb detonates immediately on contact
			trigger_explosion_flag = true
		else:
			get_tree().create_timer(2.5).timeout.connect(destroy_bird)

func explode():
	# Play explosion sound
	var scene = get_tree().current_scene
	if scene and scene.has_method("play_sound"):
		scene.play_sound("explosion")
		
	# Trigger radial blast particles
	spawn_explosion_particles()
	
	# Blast physics impulse query
	var query = PhysicsShapeQueryParameters2D.new()
	var blast_shape = CircleShape2D.new()
	blast_shape.radius = 200.0 # blast range
	query.shape = blast_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0xFFFFFFFF # Check all collision masks
	
	var results = get_world_2d().direct_space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider is RigidBody2D and collider != self:
			var dir = collider.global_position - global_position
			var distance = dir.length()
			if distance < 1.0:
				distance = 1.0
			
			# Force decays linearly over distance
			var force_pct = (200.0 - distance) / 200.0
			if force_pct > 0.0:
				var push_force = force_pct * 800.0 # max push impulse
				collider.apply_central_impulse(dir.normalized() * push_force)
				
				# Deal damage to blocks/enemies
				if collider.has_method("take_damage"):
					collider.take_damage(push_force * 0.15)
					
	# Hide bird and immediately queue free
	visible = false
	collision_shape.set_deferred("disabled", true)
	set_deferred("freeze", true)
	
	emit_signal("destroyed")
	queue_free()

func spawn_explosion_particles():
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	particles.amount = 30
	particles.explosiveness = 1.0
	particles.lifetime = 0.7
	particles.one_shot = true
	
	# Fire / smoke gradient colors
	particles.color = Color(1.0, 0.45, 0.1) # Orange blast
	
	particles.spread = 180.0
	particles.gravity = Vector2(0, -100) # smoke drifts upwards
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 220.0
	particles.scale_amount_min = 8.0
	particles.scale_amount_max = 20.0
	
	particles.emitting = true
	get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func destroy_bird():
	if is_being_destroyed:
		return
	if freeze and not was_launched:
		return
	is_being_destroyed = true
	set_deferred("freeze", true)
	
	var tween = create_tween()
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)
	if trail_line:
		tween.parallel().tween_property(trail_line, "modulate:a", 0.0, fade_duration)
	
	tween.finished.connect(func():
		emit_signal("destroyed")
		queue_free()
	)
