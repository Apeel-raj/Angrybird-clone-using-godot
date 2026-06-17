extends Node

var sounds = {}
var players: Array[AudioStreamPlayer] = []

func _ready():
	# Generate and cache all procedural sound effects
	sounds["pop"] = generate_pop_sound()
	sounds["explosion"] = generate_explosion_sound()
	sounds["wood_break"] = generate_wood_sound()
	sounds["ice_break"] = generate_ice_sound()
	sounds["stone_hit"] = generate_stone_sound()
	sounds["launch"] = generate_launch_sound()
	sounds["stretch"] = generate_stretch_sound()
	sounds["power"] = generate_power_sound()
	
	# Pre-create a pool of audio players for polyphony
	for i in range(8):
		var player = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func play(sound_name: String):
	if not sounds.has(sound_name):
		return
		
	# Find an idle audio player
	var played = false
	for player in players:
		if not player.playing:
			player.stream = sounds[sound_name]
			player.play()
			played = true
			break
			
	# If all players are busy, steal the oldest one
	if not played:
		var p = players[0]
		p.stop()
		p.stream = sounds[sound_name]
		p.play()

func create_wav(bytes: PackedByteArray, sample_rate: int) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func generate_pop_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = lerp(250.0, 800.0, t)
		phase += 2.0 * PI * freq / sample_rate
		var s = sin(phase)
		var amp = 1.0 - t
		var val = int(s * amp * 32767.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)

func generate_explosion_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	for i in range(num_samples):
		var t = float(i) / num_samples
		var s = randf() * 2.0 - 1.0
		var amp = exp(-5.0 * t)
		var val = int(s * amp * 32767.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)

func generate_wood_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var noise = randf() * 2.0 - 1.0
		phase += 2.0 * PI * 180.0 / sample_rate
		var s = lerp(noise, sin(phase), 0.3)
		var amp = 1.0 - t
		var val = int(s * amp * 32767.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)

func generate_ice_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = lerp(2200.0, 1800.0, t)
		phase += 2.0 * PI * freq / sample_rate
		var s = sin(phase)
		var amp = exp(-4.0 * t)
		var val = int(s * amp * 32767.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)

func generate_stone_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.25
	var num_samples = int(sample_rate * duration)
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		phase += 2.0 * PI * 75.0 / sample_rate
		var s_wave = 1.0 if sin(phase) > 0.0 else -1.0
		var noise = randf() * 2.0 - 1.0
		var s = lerp(s_wave, noise, 0.4)
		var amp = 1.0 - t
		var val = int(s * amp * 32767.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)

func generate_launch_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = lerp(150.0, 550.0, t)
		phase += 2.0 * PI * freq / sample_rate
		var s = sin(phase)
		var amp = 1.0 - t
		var val = int(s * amp * 32767.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)

func generate_stretch_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.05
	var num_samples = int(sample_rate * duration)
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		phase += 2.0 * PI * 120.0 / sample_rate
		var s = sin(phase)
		var amp = 0.0 if (i % 200 > 50) else 1.0
		var val = int(s * amp * 12000.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)

func generate_power_sound() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var sample_rate = 22050
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = lerp(350.0, 1100.0, t)
		phase += 2.0 * PI * freq / sample_rate
		var s = sin(phase)
		var amp = 1.0 - t
		var val = int(s * amp * 22000.0)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	return create_wav(bytes, sample_rate)
