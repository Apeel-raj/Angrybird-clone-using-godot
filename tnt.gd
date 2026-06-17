extends RigidBody2D

signal exploded(points)

@export var max_health: float = 10.0
@export var impact_threshold: float = 55.0
@export var damage_multiplier: float = 0.5
@export var score_value: int = 2000
@export var blast_radius: float = 230.0
@export var blast_force: float = 900.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health: float = 10.0
var is_detonated: bool = false
var trigger_detonation_flag: bool = false
var spawn_time: float = 0.0

func _ready():
	health = max_health
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	add_to_group("tnt")

func _on_body_entered(body):
	if is_detonated or spawn_time < 0.3:
		return
		
	var contact_speed = 0.0
	if body is RigidBody2D:
		contact_speed = (linear_velocity - body.linear_velocity).length()
	else:
		contact_speed = linear_velocity.length()
		
	if contact_speed > impact_threshold:
		trigger_detonation_flag = true

func _physics_process(delta):
	if spawn_time < 0.5:
		spawn_time += delta
		
	if trigger_detonation_flag:
		trigger_detonation_flag = false
		detonate()

func take_damage(amount: float):
	if is_detonated:
		return
	health -= amount
	if health <= 0:
		trigger_detonation_flag = true

func detonate():
	if is_detonated:
		return
	is_detonated = true
	
	emit_signal("exploded", score_value)
	
	# Play explosion sound
	var scene = get_tree().current_scene
	if scene and scene.has_method("play_sound"):
		scene.play_sound("explosion")
		
	# Spawn blast particles
	spawn_explosion_particles()
	
	# Direct physics query to apply force to nearby RigidBodies
	var query = PhysicsShapeQueryParameters2D.new()
	var blast_shape = CircleShape2D.new()
	blast_shape.radius = blast_radius
	query.shape = blast_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0xFFFFFFFF
	
	var results = get_world_2d().direct_space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider is RigidBody2D and collider != self:
			var dir = collider.global_position - global_position
			var distance = dir.length()
			if distance < 1.0:
				distance = 1.0
				
			var force_pct = (blast_radius - distance) / blast_radius
			if force_pct > 0.0:
				var push_force = force_pct * blast_force
				collider.apply_central_impulse(dir.normalized() * push_force)
				
				if collider.has_method("take_damage"):
					collider.take_damage(push_force * 0.15)
					
	# Hide and disable collision, then free after delay
	visible = false
	collision_shape.set_deferred("disabled", true)
	set_deferred("freeze", true)
	
	get_tree().create_timer(1.0).timeout.connect(queue_free)

func spawn_explosion_particles():
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	particles.amount = 35
	particles.explosiveness = 1.0
	particles.lifetime = 0.75
	particles.one_shot = true
	particles.color = Color(1.0, 0.25, 0.05) # Fiery red-orange
	
	particles.spread = 180.0
	particles.gravity = Vector2(0, -180) # smoke rises
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 250.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 15.0
	
	particles.emitting = true
	get_tree().create_timer(0.9).timeout.connect(particles.queue_free)
