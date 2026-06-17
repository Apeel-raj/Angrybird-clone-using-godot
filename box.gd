extends RigidBody2D

@export var max_health: float = 60.0
@export var impact_threshold: float = 100.0
@export var damage_multiplier: float = 0.4
@export var particle_color: Color = Color(0.63, 0.42, 0.25) # Default wood color

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health: float = 60.0
var is_destroyed: bool = false
var spawn_time: float = 0.0

func _ready():
	health = max_health
	# Enable collision contact monitoring
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if spawn_time < 0.5:
		spawn_time += delta

func _on_body_entered(body):
	if is_destroyed or spawn_time < 0.3:
		return
		
	var contact_speed = 0.0
	if body is RigidBody2D:
		contact_speed = (linear_velocity - body.linear_velocity).length()
	else:
		contact_speed = linear_velocity.length()
		
	if contact_speed > impact_threshold:
		var damage = (contact_speed - impact_threshold) * damage_multiplier
		take_damage(damage)

func take_damage(amount: float):
	health -= amount
	
	# Visual damage cue: make the box darker and tinted red as it takes damage
	if sprite:
		var health_pct = max(0.0, health / max_health)
		sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(0.55, 0.45, 0.45), 1.0 - health_pct)
		
	if health <= 0:
		destroy_box()

func destroy_box():
	if is_destroyed:
		return
	is_destroyed = true
	
	# Play breaking sound based on block type
	var scene = get_tree().current_scene
	if scene and scene.has_method("play_sound"):
		if scene_file_path.contains("ice"):
			scene.play_sound("ice_break")
		elif scene_file_path.contains("stone"):
			scene.play_sound("stone_hit")
		else:
			scene.play_sound("wood_break")
			
	# Spawn particles
	spawn_break_particles()
	
	# Disable collisions and hide sprite
	visible = false
	collision_shape.set_deferred("disabled", true)
	set_deferred("freeze", true)
	
	# Clean up box node
	get_tree().create_timer(1.0).timeout.connect(queue_free)

func spawn_break_particles():
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Styled to look like brown wooden splinters exploding
	particles.amount = 14
	particles.explosiveness = 1.0
	particles.lifetime = 0.7
	particles.one_shot = true
	particles.color = particle_color
	
	# Physics variables
	particles.spread = 180.0
	particles.gravity = Vector2(0, 600) # Pulls down under gravity
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 160.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	
	# Emit and auto-free the particle emitter after completion
	particles.emitting = true
	get_tree().create_timer(0.9).timeout.connect(particles.queue_free)
