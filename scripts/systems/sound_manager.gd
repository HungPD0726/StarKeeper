class_name SoundManager
extends Node

## Pentatonic scale frequencies (C4 pentatonic: C D E G A)
const PENTATONIC_FREQUENCIES: Array[float] = [
	261.63, 293.66, 329.63, 392.00, 440.00,
	523.25, 587.33, 659.25, 783.99, 880.00,
]

const SAMPLE_RATE: float = 22050.0
const BASE_VOLUME_DB: float = -14.0

@export_range(-30.0, 0.0, 1.0) var master_volume_db: float = -8.0


func play_star_click(star_index: int) -> void:
	var freq_index: int = star_index % PENTATONIC_FREQUENCIES.size()
	var frequency: float = PENTATONIC_FREQUENCIES[freq_index]
	_play_tone(frequency, 0.25, -12.0)


func play_edge_valid() -> void:
	# Two-note ascending chime
	_play_tone(523.25, 0.15, -14.0)
	_play_tone_delayed(659.25, 0.2, -13.0, 0.08)


func play_edge_invalid() -> void:
	# Low buzzy note
	_play_tone(185.0, 0.12, -18.0)


func play_constellation_complete() -> void:
	# Triumphant arpeggio: C5 - E5 - G5 - C6
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	for i: int in notes.size():
		_play_tone_delayed(notes[i], 0.35 - float(i) * 0.03, -10.0 + float(i) * 0.5, float(i) * 0.12)


func play_step() -> void:
	# Short noise burst for footstep
	var frequency: float = randf_range(120.0, 200.0)
	_play_tone(frequency, 0.04, -22.0)


func play_notification() -> void:
	_play_tone(880.0, 0.1, -16.0)
	_play_tone_delayed(1108.73, 0.15, -15.0, 0.06)


# ── Tone generation ──────────────────────────────────────────────────

func _play_tone(frequency: float, duration: float, volume_db: float) -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = _generate_sine_wav(frequency, duration)
	player.stream = stream
	player.volume_db = master_volume_db + volume_db - BASE_VOLUME_DB
	player.bus = &"Master"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _play_tone_delayed(frequency: float, duration: float, volume_db: float, delay: float) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(func() -> void: _play_tone(frequency, duration, volume_db))


func _generate_sine_wav(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit samples = 2 bytes each

	for i: int in sample_count:
		var t: float = float(i) / SAMPLE_RATE
		# Envelope: quick attack, exponential decay
		var envelope: float = exp(-t * 8.0) * minf(t * 200.0, 1.0)
		# Sine wave with slight harmonics for warmth
		var sample: float = sin(TAU * frequency * t) * 0.7
		sample += sin(TAU * frequency * 2.0 * t) * 0.15 * exp(-t * 12.0)
		sample += sin(TAU * frequency * 3.0 * t) * 0.08 * exp(-t * 16.0)
		sample *= envelope

		var value: int = clampi(int(sample * 24000.0), -32768, 32767)
		data.encode_s16(i * 2, value)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(SAMPLE_RATE)
	wav.data = data
	wav.stereo = false
	return wav
