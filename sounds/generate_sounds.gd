extends EditorScript

func _run():
	var dir = DirAccess.open("res://")
	if dir.dir_exists("sounds"):
		pass
	else:
		dir.make_dir("sounds")

	var click = _generate_click()
	var flip = _generate_flip()
	var gameover = _generate_gameover()

	_save_sample(click, "res://sounds/click.tres")
	_save_sample(flip, "res://sounds/flip.tres")
	_save_sample(gameover, "res://sounds/gameover.tres")

	print("Generated click.tres, flip.tres, gameover.tres")

func _generate_click() -> AudioStreamWAV:
	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.stereo = false
	sample.mix_rate = 44100
	var length = int(44100 * 0.1)
	var data := PackedInt16Array()
	for i in length:
		var t = float(i) / 44100.0
		var envelope = exp(-t * 40.0)
		var value = int(envelope * sin(2.0 * PI * 1000.0 * t) * 32767.0)
		data.append(value)
	sample.set_data(data)
	return sample

func _generate_flip() -> AudioStreamWAV:
	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.stereo = false
	sample.mix_rate = 44100
	var length = int(44100 * 0.2)
	var data := PackedInt16Array()
	for i in length:
		var t = float(i) / 44100.0
		var envelope = exp(-t * 8.0)
		var freq = 800.0 - t * 2500.0
		var value = int(envelope * sin(2.0 * PI * freq * t) * 32767.0)
		data.append(value)
	sample.set_data(data)
	return sample

func _generate_gameover() -> AudioStreamWAV:
	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.stereo = false
	sample.mix_rate = 44100
	var length = int(44100 * 0.5)
	var data := PackedInt16Array()
	for i in length:
		var t = float(i) / 44100.0
		var envelope = exp(-t * 2.0)
		var v1 = envelope * sin(2.0 * PI * 523.0 * t)
		var v2 = envelope * sin(2.0 * PI * 784.0 * t)
		var value = int((v1 + v2) * 0.5 * 32767.0)
		data.append(value)
	sample.set_data(data)
	return sample

func _save_sample(sample: AudioStreamWAV, path: String):
	ResourceSaver.save(sample, path)
