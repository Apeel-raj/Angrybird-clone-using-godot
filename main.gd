extends Node2D

@export var bird_scene: PackedScene = preload("res://bird.tscn")
@export var box_scene: PackedScene = preload("res://box.tscn")
@export var pig_scene: PackedScene = preload("res://pig.tscn")
@export var tnt_scene: PackedScene = preload("res://tnt.tscn")
@export var ice_scene: PackedScene = preload("res://ice.tscn")
@export var stone_scene: PackedScene = preload("res://stone.tscn")

@onready var slingshot = $Slingshot
@onready var camera = $Camera2D
@onready var level_objects_container = $LevelObjects

# UI Hookups
@onready var score_label = $CanvasLayer/UI/TopBar/ScoreLabel
@onready var birds_label = $CanvasLayer/UI/TopBar/BirdsLabel
@onready var level_title_label = $CanvasLayer/UI/TopBar/LevelTitleLabel
@onready var reset_button = $CanvasLayer/UI/TopBar/ResetButton
@onready var level_select_menu_button = $CanvasLayer/UI/TopBar/LevelSelectButton

@onready var game_status_panel = $CanvasLayer/UI/GameStatusPanel
@onready var status_title = $CanvasLayer/UI/GameStatusPanel/Title
@onready var status_score = $CanvasLayer/UI/GameStatusPanel/ScoreValue
@onready var retry_button = $CanvasLayer/UI/GameStatusPanel/RetryButton
@onready var next_level_button = $CanvasLayer/UI/GameStatusPanel/NextLevelButton

@onready var level_selector_panel = $CanvasLayer/UI/LevelSelector
@onready var level_grid = $CanvasLayer/UI/LevelSelector/GridContainer

# Bird Type Enum matches bird.gd
enum BirdType { RED, YELLOW, BOMB, BLUE }

var current_level_index: int = 0
var score: int = 0
var birds_left: int = 3
var active_bird: RigidBody2D = null
var is_level_ended: bool = false
var camera_target: Node2D = null
var default_camera_pos: Vector2 = Vector2.ZERO
var initial_camera_zoom: Vector2 = Vector2.ZERO
var birds_in_flight: Array[RigidBody2D] = []
var queued_birds: Array[RigidBody2D] = []

# Level layout definitions
var levels = [
	# Level 1: The Gate
	{
		"name": "Level 1: The Gate",
		"birds": [BirdType.RED, BirdType.RED, BirdType.YELLOW],
		"objects": [
			{"type": "box", "pos": Vector2(800, 542.4)},
			{"type": "box", "pos": Vector2(900, 542.4)},
			{"type": "pig", "pos": Vector2(850, 542.4)},
			{"type": "box", "pos": Vector2(800, 491.2)},
			{"type": "box", "pos": Vector2(900, 491.2)},
			{"type": "box", "pos": Vector2(824.4, 440.0)},
			{"type": "box", "pos": Vector2(875.6, 440.0)},
			{"type": "pig", "pos": Vector2(850, 395.2)}
		]
	},
	# Level 2: TNT Explosive Intro
	{
		"name": "Level 2: TNT Blast",
		"birds": [BirdType.RED, BirdType.YELLOW],
		"objects": [
			{"type": "box", "pos": Vector2(790, 542.4)},
			{"type": "tnt", "pos": Vector2(850, 542.4)},
			{"type": "box", "pos": Vector2(910, 542.4)},
			{"type": "box", "pos": Vector2(850, 491.2)},
			{"type": "pig", "pos": Vector2(850, 440.0)}
		]
	},
	# Level 3: The Split Challenge (Blue Bird + Ice)
	{
		"name": "Level 3: Ice & Split",
		"birds": [BirdType.BLUE, BirdType.BLUE, BirdType.RED],
		"objects": [
			{"type": "ice", "pos": Vector2(760, 542.4)},
			{"type": "ice", "pos": Vector2(820, 542.4)},
			{"type": "ice", "pos": Vector2(880, 542.4)},
			{"type": "ice", "pos": Vector2(940, 542.4)},
			{"type": "pig", "pos": Vector2(790, 542.4)},
			{"type": "pig", "pos": Vector2(850, 542.4)},
			{"type": "pig", "pos": Vector2(910, 542.4)},
			{"type": "ice", "pos": Vector2(790, 491.2)},
			{"type": "ice", "pos": Vector2(910, 491.2)}
		]
	},
	# Level 4: TNT Chain Blast
	{
		"name": "Level 4: Chain Reaction",
		"birds": [BirdType.YELLOW, BirdType.RED],
		"objects": [
			{"type": "box", "pos": Vector2(750, 542.4)},
			{"type": "tnt", "pos": Vector2(810, 542.4)},
			{"type": "box", "pos": Vector2(870, 542.4)},
			{"type": "tnt", "pos": Vector2(930, 542.4)},
			{"type": "box", "pos": Vector2(990, 542.4)},
			{"type": "pig", "pos": Vector2(810, 491.2)},
			{"type": "pig", "pos": Vector2(930, 491.2)},
			{"type": "box", "pos": Vector2(870, 491.2)},
			{"type": "pig", "pos": Vector2(870, 440.0)}
		]
	},
	# Level 5: The Bomb Fortress (Stone Columns)
	{
		"name": "Level 5: Heavy Fortress",
		"birds": [BirdType.BOMB, BirdType.RED, BirdType.YELLOW],
		"objects": [
			{"type": "stone", "pos": Vector2(770, 542.4)},
			{"type": "stone", "pos": Vector2(830, 542.4)},
			{"type": "stone", "pos": Vector2(890, 542.4)},
			{"type": "stone", "pos": Vector2(950, 542.4)},
			{"type": "stone", "pos": Vector2(800, 491.2)},
			{"type": "stone", "pos": Vector2(860, 491.2)},
			{"type": "stone", "pos": Vector2(920, 491.2)},
			{"type": "box", "pos": Vector2(830, 440.0)},
			{"type": "box", "pos": Vector2(890, 440.0)},
			{"type": "pig", "pos": Vector2(860, 388.8)},
			{"type": "ice", "pos": Vector2(860, 337.6)},
			{"type": "pig", "pos": Vector2(860, 286.4)}
		]
	},
	# Level 6: TNT Pillar
	{
		"name": "Level 6: Explosive Pillar",
		"birds": [BirdType.YELLOW, BirdType.BOMB],
		"objects": [
			{"type": "box", "pos": Vector2(850, 542.4)},
			{"type": "box", "pos": Vector2(850, 491.2)},
			{"type": "tnt", "pos": Vector2(850, 440.0)},
			{"type": "box", "pos": Vector2(850, 388.8)},
			{"type": "box", "pos": Vector2(850, 337.6)},
			{"type": "pig", "pos": Vector2(850, 286.4)},
			# Left stable tower
			{"type": "box", "pos": Vector2(760, 542.4)},
			{"type": "box", "pos": Vector2(760, 491.2)},
			{"type": "pig", "pos": Vector2(760, 440.0)},
			# Right stable tower
			{"type": "box", "pos": Vector2(940, 542.4)},
			{"type": "box", "pos": Vector2(940, 491.2)},
			{"type": "pig", "pos": Vector2(940, 440.0)}
		]
	},
	# Level 7: The Sky Bridge (Stable columns + Ice bridge + center TNT)
	{
		"name": "Level 7: The Sky Bridge",
		"birds": [BirdType.BLUE, BirdType.YELLOW, BirdType.BOMB],
		"objects": [
			# Supporting Stone Columns
			{"type": "stone", "pos": Vector2(760, 542.4)},
			{"type": "stone", "pos": Vector2(760, 491.2)},
			{"type": "stone", "pos": Vector2(820, 542.4)},
			{"type": "stone", "pos": Vector2(820, 491.2)},
			{"type": "stone", "pos": Vector2(880, 542.4)},
			{"type": "stone", "pos": Vector2(880, 491.2)},
			{"type": "stone", "pos": Vector2(940, 542.4)},
			{"type": "stone", "pos": Vector2(940, 491.2)},
			# Ice Bridge
			{"type": "ice", "pos": Vector2(760, 440.0)},
			{"type": "ice", "pos": Vector2(820, 440.0)},
			{"type": "ice", "pos": Vector2(880, 440.0)},
			{"type": "ice", "pos": Vector2(940, 440.0)},
			# Center Arch and targets
			{"type": "tnt", "pos": Vector2(850, 388.8)},
			{"type": "pig", "pos": Vector2(820, 388.8)},
			{"type": "pig", "pos": Vector2(880, 388.8)},
			{"type": "pig", "pos": Vector2(850, 337.6)}
		]
	},
	# Level 8: Falling Dominos
	{
		"name": "Level 8: Falling Dominos",
		"birds": [BirdType.RED, BirdType.YELLOW, BirdType.BLUE],
		"objects": [
			{"type": "box", "pos": Vector2(740, 542.4)},
			{"type": "box", "pos": Vector2(740, 491.2)},
			{"type": "pig", "pos": Vector2(740, 440.0)},
			
			{"type": "box", "pos": Vector2(820, 542.4)},
			{"type": "box", "pos": Vector2(820, 491.2)},
			{"type": "pig", "pos": Vector2(820, 440.0)},
			
			{"type": "box", "pos": Vector2(900, 542.4)},
			{"type": "box", "pos": Vector2(900, 491.2)},
			{"type": "pig", "pos": Vector2(900, 440.0)},
			
			{"type": "tnt", "pos": Vector2(980, 542.4)},
			{"type": "pig", "pos": Vector2(980, 491.2)}
		]
	},
	# Level 9: The Castle Vault (Stone & Ice Vault)
	{
		"name": "Level 9: The Castle Vault",
		"birds": [BirdType.BOMB, BirdType.BLUE, BirdType.YELLOW],
		"objects": [
			# Outer Stone Walls
			{"type": "stone", "pos": Vector2(740, 542.4)},
			{"type": "stone", "pos": Vector2(740, 491.2)},
			{"type": "stone", "pos": Vector2(740, 440.0)},
			{"type": "stone", "pos": Vector2(940, 542.4)},
			{"type": "stone", "pos": Vector2(940, 491.2)},
			{"type": "stone", "pos": Vector2(940, 440.0)},
			# Inner Ice ceiling & floor
			{"type": "ice", "pos": Vector2(840, 542.4)},
			{"type": "tnt", "pos": Vector2(840, 491.2)},
			{"type": "ice", "pos": Vector2(840, 440.0)},
			# Targets
			{"type": "pig", "pos": Vector2(790, 542.4)},
			{"type": "pig", "pos": Vector2(890, 542.4)},
			{"type": "pig", "pos": Vector2(840, 388.8)}
		]
	},
	# Level 10: Ultimate Castle (Mixed Materials)
	{
		"name": "Level 10: Ultimate Castle",
		"birds": [BirdType.RED, BirdType.YELLOW, BirdType.BLUE, BirdType.BOMB],
		"objects": [
			# Left Tower (Stone)
			{"type": "stone", "pos": Vector2(730, 542.4)},
			{"type": "stone", "pos": Vector2(730, 491.2)},
			{"type": "stone", "pos": Vector2(790, 542.4)},
			{"type": "stone", "pos": Vector2(790, 491.2)},
			{"type": "box", "pos": Vector2(760, 440.0)},
			{"type": "pig", "pos": Vector2(760, 542.4)},
			{"type": "pig", "pos": Vector2(760, 388.8)},
			
			# Center Gate (Wood)
			{"type": "box", "pos": Vector2(830, 542.4)},
			{"type": "box", "pos": Vector2(830, 491.2)},
			{"type": "box", "pos": Vector2(830, 440.0)},
			{"type": "box", "pos": Vector2(890, 542.4)},
			{"type": "box", "pos": Vector2(890, 491.2)},
			{"type": "box", "pos": Vector2(890, 440.0)},
			{"type": "tnt", "pos": Vector2(860, 542.4)},
			{"type": "pig", "pos": Vector2(860, 491.2)},
			{"type": "box", "pos": Vector2(860, 388.8)},
			{"type": "pig", "pos": Vector2(860, 337.6)},
			
			# Right Tower (Stone)
			{"type": "stone", "pos": Vector2(930, 542.4)},
			{"type": "stone", "pos": Vector2(930, 491.2)},
			{"type": "stone", "pos": Vector2(990, 542.4)},
			{"type": "stone", "pos": Vector2(990, 491.2)},
			{"type": "box", "pos": Vector2(960, 440.0)},
			{"type": "pig", "pos": Vector2(960, 542.4)},
			{"type": "pig", "pos": Vector2(960, 388.8)}
		]
	},
	# Level 11: Ice Castle
	{
		"name": "Level 11: Ice Castle",
		"birds": [BirdType.BLUE, BirdType.BLUE, BirdType.YELLOW],
		"objects": [
			{"type": "ice", "pos": Vector2(750, 542.4)},
			{"type": "ice", "pos": Vector2(810, 542.4)},
			{"type": "tnt", "pos": Vector2(870, 542.4)},
			{"type": "ice", "pos": Vector2(930, 542.4)},
			{"type": "ice", "pos": Vector2(990, 542.4)},
			{"type": "ice", "pos": Vector2(780, 491.2)},
			{"type": "pig", "pos": Vector2(840, 491.2)},
			{"type": "pig", "pos": Vector2(900, 491.2)},
			{"type": "ice", "pos": Vector2(960, 491.2)},
			{"type": "ice", "pos": Vector2(810, 440.0)},
			{"type": "tnt", "pos": Vector2(870, 440.0)},
			{"type": "ice", "pos": Vector2(930, 440.0)},
			{"type": "pig", "pos": Vector2(870, 388.8)}
		]
	},
	# Level 12: Stone Mountain
	{
		"name": "Level 12: Stone Mountain",
		"birds": [BirdType.BOMB, BirdType.BOMB, BirdType.YELLOW],
		"objects": [
			{"type": "stone", "pos": Vector2(750, 542.4)},
			{"type": "stone", "pos": Vector2(810, 542.4)},
			{"type": "stone", "pos": Vector2(870, 542.4)},
			{"type": "stone", "pos": Vector2(930, 542.4)},
			{"type": "stone", "pos": Vector2(780, 491.2)},
			{"type": "pig", "pos": Vector2(840, 491.2)},
			{"type": "pig", "pos": Vector2(900, 491.2)},
			{"type": "stone", "pos": Vector2(960, 491.2)},
			{"type": "stone", "pos": Vector2(810, 440.0)},
			{"type": "tnt", "pos": Vector2(870, 440.0)},
			{"type": "stone", "pos": Vector2(930, 440.0)},
			{"type": "pig", "pos": Vector2(870, 388.8)}
		]
	}
]

func _ready():
	randomize()
	default_camera_pos = camera.global_position
	initial_camera_zoom = camera.zoom
	
	# Instantiate SoundManager dynamically
	var sound_manager_script = load("res://sound_manager.gd")
	var sound_manager = Node.new()
	sound_manager.set_script(sound_manager_script)
	sound_manager.name = "SoundManager"
	add_child(sound_manager)
	
	# Connect UI buttons
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_reset_pressed)
	if next_level_button:
		next_level_button.pressed.connect(_on_next_level_pressed)
	if level_select_menu_button:
		level_select_menu_button.pressed.connect(show_level_selector)
		
	# Connect slingshot signals
	if slingshot:
		slingshot.bird_launched.connect(_on_bird_launched)
		
	# Connect Level Selector grid buttons
	if level_grid:
		for i in range(level_grid.get_child_count()):
			var btn = level_grid.get_child(i)
			if btn is Button:
				var level_idx = i
				btn.pressed.connect(func(): select_level(level_idx))
				
	# Show level selector by default to choose a starting stage
	show_level_selector()

func show_level_selector():
	level_selector_panel.visible = true
	game_status_panel.visible = false
	if active_bird and is_instance_valid(active_bird):
		active_bird.queue_free()
		active_bird = null

func select_level(level_index: int):
	current_level_index = level_index
	level_selector_panel.visible = false
	load_level(current_level_index)

func load_level(level_idx: int):
	# Clear old level elements
	if active_bird and is_instance_valid(active_bird):
		active_bird.queue_free()
		active_bird = null
		
	# Clear all old birds from the birds group (including clones)
	for old_bird in get_tree().get_nodes_in_group("birds"):
		if is_instance_valid(old_bird):
			old_bird.queue_free()
			
	birds_in_flight.clear()
	queued_birds.clear()
		
	for child in level_objects_container.get_children():
		child.queue_free()
		
	# Setup level data
	var level_data = levels[level_idx]
	score = 0
	is_level_ended = false
	camera_target = null
	camera.global_position = default_camera_pos
	camera.zoom = initial_camera_zoom
	
	# Build layout objects
	for obj_data in level_data["objects"]:
		var instance = null
		match obj_data["type"]:
			"box":
				instance = box_scene.instantiate()
				instance.tree_exited.connect(func(): 
					if not is_level_ended:
						score += 500
						update_ui()
				)
			"ice":
				instance = ice_scene.instantiate()
				instance.tree_exited.connect(func(): 
					if not is_level_ended:
						score += 250
						update_ui()
				)
			"stone":
				instance = stone_scene.instantiate()
				instance.tree_exited.connect(func(): 
					if not is_level_ended:
						score += 750
						update_ui()
				)
			"pig":
				instance = pig_scene.instantiate()
				# Connect pig popped score
				instance.popped.connect(_on_pig_popped)
			"tnt":
				instance = tnt_scene.instantiate()
				# Connect tnt explosion score
				instance.exploded.connect(func(pts):
					score += pts
					update_ui()
					# Check level state in next frames
					call_deferred("check_victory_condition")
				)
				
		if instance:
			instance.global_position = obj_data["pos"]
			# Add to the clean containers
			level_objects_container.add_child(instance)
			
	# Reset birds pool
	birds_left = level_data["birds"].size()
	
	# Instantiate all birds for the queue line
	for i in range(level_data["birds"].size()):
		var b = bird_scene.instantiate()
		b.type = level_data["birds"][i]
		b.freeze = true
		b.collision_layer = 0
		b.collision_mask = 0
		
		# Initial position in queue
		var queue_pos = Vector2(140 - i * 45, 542.4)
		b.global_position = queue_pos
		add_child(b)
		queued_birds.append(b)
		
	# Hide win/loss panel
	game_status_panel.visible = false
	
	# Update UI header
	if level_title_label:
		level_title_label.text = level_data["name"].to_upper()
		
	update_ui()
	
	# Spawn first bird
	spawn_next_bird()

func spawn_next_bird():
	if is_level_ended:
		return
		
	# Clean up any orphaned/stuck birds near the slingshot center
	for b in get_tree().get_nodes_in_group("birds"):
		if is_instance_valid(b) and b != active_bird and not queued_birds.has(b):
			if b.global_position.distance_to(slingshot.center_position) < 50.0:
				b.queue_free()
		
	# Abort spawn if a bird is already waiting on the slingshot
	if active_bird and is_instance_valid(active_bird):
		return
		
	if queued_birds.size() > 0:
		birds_left = queued_birds.size() - 1
		var next_bird = queued_birds.pop_front()
		
		active_bird = next_bird
		camera_target = null
		update_ui()
		
		# Restore collision
		next_bird.collision_layer = 1
		next_bird.collision_mask = 1
		
		# Tween the loaded bird to the slingshot center
		var tween = create_tween()
		tween.tween_property(next_bird, "global_position", slingshot.center_position, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func():
			if is_instance_valid(next_bird) and not is_level_ended:
				slingshot.load_bird(next_bird)
		)
		
		# Tween the remaining queued birds forward
		for i in range(queued_birds.size()):
			var q_bird = queued_birds[i]
			if is_instance_valid(q_bird):
				var target_pos = Vector2(140 - i * 45, 542.4)
				var q_tween = create_tween()
				q_tween.tween_property(q_bird, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		# Give blocks time to settle before declaring game over
		get_tree().create_timer(3.0).timeout.connect(check_game_over)

func _on_bird_launched(bird_node):
	camera_target = bird_node
	active_bird = null
	register_bird_in_flight(bird_node)

func register_bird_in_flight(bird_node: RigidBody2D):
	if not birds_in_flight.has(bird_node):
		birds_in_flight.append(bird_node)
		bird_node.destroyed.connect(func(): _on_flight_bird_destroyed(bird_node))

func _on_flight_bird_destroyed(bird_node):
	if not birds_in_flight.has(bird_node):
		return
	birds_in_flight.erase(bird_node)
	if birds_in_flight.size() == 0:
		camera_target = null
		get_tree().create_timer(1.0).timeout.connect(func():
			if get_alive_pigs_count() == 0:
				trigger_victory()
			else:
				spawn_next_bird()
		)

func _on_pig_popped(points):
	score += points
	update_ui()
	call_deferred("check_victory_condition")

func get_alive_pigs_count() -> int:
	var count = 0
	for node in get_tree().get_nodes_in_group("pigs"):
		if is_instance_valid(node) and not node.is_dead:
			count += 1
	return count

func check_victory_condition():
	if get_alive_pigs_count() == 0:
		trigger_victory()

func check_game_over():
	if is_level_ended:
		return
		
	if get_alive_pigs_count() > 0:
		trigger_game_over()
	else:
		trigger_victory()

func trigger_victory():
	if is_level_ended:
		return
	is_level_ended = true
	
	status_title.text = "LEVEL CLEAR!"
	
	# Award 10,000 points bonus for each unused bird
	var bonus = birds_left * 10000
	score += bonus
	
	status_score.text = "FINAL SCORE: " + str(score)
	game_status_panel.visible = true
	
	# Enable next level button if there is a next level
	if next_level_button:
		next_level_button.visible = current_level_index < levels.size() - 1

func trigger_game_over():
	if is_level_ended:
		return
	is_level_ended = true
	
	status_title.text = "GAME OVER"
	status_score.text = "FINAL SCORE: " + str(score)
	game_status_panel.visible = true
	
	if next_level_button:
		next_level_button.visible = false

func update_ui():
	if score_label:
		score_label.text = "SCORE: " + str(score)
	if birds_label:
		# Format ammo symbols visually depending on bird types remaining
		var level_data = levels[current_level_index]
		var birds_list = level_data["birds"]
		var ammo_text = "NEXT: "
		var start_idx = birds_list.size() - (birds_left + 1)
		
		# Show visual string representation of birds pool
		if start_idx >= 0 and start_idx < birds_list.size():
			for i in range(start_idx, birds_list.size()):
				match birds_list[i]:
					BirdType.RED: ammo_text += "[R] "
					BirdType.YELLOW: ammo_text += "[Y] "
					BirdType.BOMB: ammo_text += "[B] "
					BirdType.BLUE: ammo_text += "[U] "
		else:
			ammo_text += "NONE"
			
		birds_label.text = ammo_text

func _process(delta):
	# Camera smoothly tracks bird in flight
	if camera_target and is_instance_valid(camera_target):
		var target_pos = camera_target.global_position
		target_pos.x = clamp(target_pos.x, default_camera_pos.x, 1500.0)
		target_pos.y = clamp(target_pos.y, 100.0, default_camera_pos.y)
		
		camera.global_position = camera.global_position.lerp(target_pos, 4.0 * delta)
		
		# Zoom out slightly for high shots
		var height_diff = default_camera_pos.y - camera.global_position.y
		var zoom_factor = clamp(1.0 - (height_diff * 0.0008), 0.8, 1.0)
		camera.zoom = camera.zoom.lerp(initial_camera_zoom * zoom_factor, 1.5 * delta)
	else:
		# Return smoothly back home
		camera.global_position = camera.global_position.lerp(default_camera_pos, 2.5 * delta)
		camera.zoom = camera.zoom.lerp(initial_camera_zoom, 2.5 * delta)

func _on_reset_pressed():
	load_level(current_level_index)

func _on_next_level_pressed():
	if current_level_index < levels.size() - 1:
		current_level_index += 1
		load_level(current_level_index)

func play_sound(sound_name: String):
	if has_node("SoundManager"):
		get_node("SoundManager").play(sound_name)
