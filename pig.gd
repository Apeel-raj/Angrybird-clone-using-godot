extends RigidBody2D

signal popped(points)

@export var max_health: float = 20.0
@export var impact_threshold: float = 50.0
@export var damage_multiplier: float = 0.7
@export var score_value: int = 5000

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health: float = 25.0
var is_dead: bool = false
var spawn_time: float = 0.0

func _ready():
	health = max_health
	add_to_group("pigs")
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if spawn_time < 0.5:
		spawn_time += delta

func _on_body_entered(body):
	if is_dead or spawn_time < 0.3:
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
	
	# Visual cue: blend the pig green sprite to a darker/reddish color as health drops
	if sprite:
		var health_pct = max(0.0, health / max_health)
		sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(0.6, 0.45, 0.45), 1.0 - health_pct)
		
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	
	emit_signal("popped", score_value)
	
	# Play pop sound
	var scene = get_tree().current_scene
	if scene and scene.has_method("play_sound"):
		scene.play_sound("pop")
		
	# Spawn dust explosion particles
	spawn_death_particles()
	
	# Disable collision and visibility
	visible = false
	collision_shape.set_deferred("disabled", true)
	set_deferred("freeze", true)
	
	# Free node after particles complete
	get_tree().create_timer(1.0).timeout.connect(queue_free)

func spawn_death_particles():
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Puffy explosion of light green dust
	particles.amount = 18
	particles.explosiveness = 1.0
	particles.lifetime = 0.55
	particles.one_shot = true
	particles.color = Color(0.70, 0.90, 0.70) # Light green pig puff
	
	particles.spread = 180.0
	particles.gravity = Vector2(0, 150) # gentle drift down
	particles.initial_velocity_min = 55.0
	particles.initial_velocity_max = 135.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 11.0
	
	particles.emitting = true
	get_tree().create_timer(0.8).timeout.connect(particles.queue_free)
