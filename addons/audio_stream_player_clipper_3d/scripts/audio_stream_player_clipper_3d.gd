@tool
class_name AudioStreamPlayerClipper3D extends Node

@export_group("Channels")
@export var use_channels: bool = false:
	set(value):
		use_channels = value
		if play: play = false
		if not use_channels and alternate_channel_by_play: alternate_channel_by_play = false
@export var alternate_channel_by_play: bool = false:
	set(value):
		alternate_channel_by_play = value
		if alternate_channel_by_play and not use_channels: alternate_channel_by_play = false
		if alternate_channel_by_play and loop:
			loop = false
			push_warning("The loop property has been disabled since the alternate_channel_by_play property has been enabled")
		if alternate_channel_by_play and play: play = false
		if alternate_channel_by_play and auto_play:
			auto_play = false
			push_warning("Autoplay cannot be enabled when alternate_channel_by_play is true")
@export var audio_channels: Array[Channel] = []:
	set(value):
		audio_channels = value

@export_group("Audio Stream Player")
@export_subgroup("Audio Stream")
@export var audio_stream: AudioStream:
	set(value):
		audio_stream = value
		_audio_stream_initializer()
		
@export_subgroup("Audio Control")
@export_range(-80, 80, 0.1, "suffix:dB") var volume_db: float = 0.0:
	set(value):
		volume_db = value
		if _audio_stream_player:
			_audio_stream_player.volume_db = volume_db
@export_range(-24, 6, 0.1, "suffix:dB") var max_db: float = 3.0:
	set(value):
		max_db = value
		if _audio_stream_player:
			_audio_stream_player.max_db = max_db
@export_range(0.1, 100, 0.1) var unit_size: float = 10.0:
	set(value):
		unit_size = value
		if _audio_stream_player:
			_audio_stream_player.unit_size = unit_size
@export_range(0.1, 4.0, 0.1) var pitch_scale: float = 1.0:
	set(value):
		pitch_scale = value
		if _audio_stream_player:
			_audio_stream_player.pitch_scale = pitch_scale
			_current_duration = (_current_end_time - _current_start_time) / pitch_scale

		if _timer_channels and _current_duration > 0:
			_timer_channels.wait_time = _current_duration
@export var auto_play: bool = false:
	set(value):
		if alternate_channel_by_play and value:
			auto_play = false
			push_warning("Autoplay cannot be enabled when alternate_channel_by_play is true")
			return
			
		auto_play = value
		if _audio_stream_player:
			if not use_channels or auto_play == false: _audio_stream_player.autoplay = auto_play
@export_range(0.0, 3.0, 0.1) var panning_strength: float = 1.0:
	set(value):
		panning_strength = value
		if _audio_stream_player:
			_audio_stream_player.panning_strength = panning_strength
@export_range(1, 4, 1) var max_polyphony = 1:
	set(value):
		max_polyphony = value
		if _audio_stream_player:
			_audio_stream_player.max_polyphony = max_polyphony
@export var loop: bool = false:
	set(value):
		if alternate_channel_by_play:
			loop = false
			push_warning("When the alternate_channel_by_play property is enabled, looping cannot be enabled")
			return
		loop = value

		if not audio_stream:
			if loop: push_warning("You have to set the audio source first")
			loop = false
			return

		if loop:
			if audio_stream is AudioStreamMP3 or audio_stream is AudioStreamMicrophone or audio_stream is AudioStreamRandomizer or audio_stream is AudioStreamPolyphonic or audio_stream is AudioStreamOggVorbis:
				audio_stream.loop = loop
			else:
				loop = false
				push_warning("The loop property does not exist in the selected file type")
@export_range(0, 4096, 1, "suffix:m") var max_distance: int = 2000:
	set(value):
		max_distance = value
		if _audio_stream_player:
			_audio_stream_player.max_distance = max_distance

@export_subgroup("Reproduction")
@export var play: bool = false:
	set(value):
		if not _audio_stream_player or not _audio_stream_player.get_parent() or not audio_stream:
			play = false
			push_warning("You cannot play audio without first defining the audio source")
			return
		
		if use_channels and audio_channels.size() == 0:
			play = false
			_set_stop()
			if pause: pause = false
			push_warning("The audio_channels property does not have any items")
			return

		play = value
		if not audio_stream:
			play = false

		if play:
			if use_channels:
				if not alternate_channel_by_play:
					_play_with_channels()
				else:
					_play_alternate_channel_by_play()
					_current_channel_index += 1
					if _current_channel_index >= audio_channels.size():
						_current_channel_index = 0
			else:
				_play_with_out_channels()
		else:
			_set_stop()
			if pause: pause = false
@export var pause: bool = false:
	set(value):
		pause = value
		if _audio_stream_player and not _audio_stream_player.playing and pause:
			pause = false
			push_warning("You can only pause the audio if it is playing")
		if pause:
			_set_pause()
		else:
			_set_contin()

@export_subgroup("Emission")
@export var emission_angle_enabled: bool = false:
	set(value):
		emission_angle_enabled = value
		if _audio_stream_player:
			_audio_stream_player.emission_angle_enabled = emission_angle_enabled
@export_range(0.1, 90.0, 0.1, "suffix:degress") var emission_angle_degrees: float = 45.0:
	set(value):
		emission_angle_degrees = value
		if _audio_stream_player:
			_audio_stream_player.emission_angle_degrees = emission_angle_degrees
@export_range(-80.0, 0.0, 0.1, "suffix:dB") var emission_angle_filter_attenuation_db: float = -24.0:
	set(value):
		emission_angle_filter_attenuation_db = value
		if _audio_stream_player:
			_audio_stream_player.emission_angle_filter_attenuation_db = emission_angle_filter_attenuation_db

@export_subgroup("Attenuation")
@export var attenuation_model: AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE:
	set(value):
		attenuation_model = value
		if _audio_stream_player:
			_audio_stream_player.attenuation_model = attenuation_model
@export_range(1, 20500, 1, "suffix:Hz") var attenuation_filter_cutoff_hz: int = 5000:
	set(value):
		attenuation_filter_cutoff_hz = value
		if _audio_stream_player:
			_audio_stream_player.attenuation_filter_cutoff_hz = attenuation_filter_cutoff_hz
@export_range(-80.0, 0.0, 0.1, "suffix:dB") var attenuation_filter_dbattenuation_filter_db: float = -24.0:
	set(value):
		attenuation_filter_dbattenuation_filter_db = value
		if _audio_stream_player:
			_audio_stream_player.attenuation_filter_db = attenuation_filter_dbattenuation_filter_db

@export_subgroup("Doppler")
@export var doppler_tracking: AudioStreamPlayer3D.DopplerTracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED:
	set(value):
		doppler_tracking = value
		if _audio_stream_player:
			_audio_stream_player.doppler_tracking = doppler_tracking

@export_subgroup("Area Mask")
@export_flags("1", "2", "3", "4") var area_mask: int = 1:
	set(value):
		area_mask = value
		_audio_stream_player.area_mask = area_mask

var _audio_stream_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
var _can_playing: bool = false

var _current_duration: float = 0.0:
	set(value):
		if value >= 0:
			_current_duration = value
		else:
			_current_duration = 0
			push_warning("Subtracting the end_time property with start_time cannot be less than zero")
var _current_start_time: float = 0.0:
	set(value):
		if value >= 0:
			_current_start_time = value
		else:
			_current_start_time = 0
			push_warning("The start_time property cannot be less than zero")
var _current_end_time: float = 0.0:
	set(value):
		if value >= 0:
			_current_end_time = value
		else:
			_current_end_time = 0
			push_warning("The end_time property cannot be less than zero")
var _current_channel_index: int = 0
var _timer_channels: Timer = Timer.new()

func _ready() -> void:
	if play: play = false

	_audio_stream_player_initializer()

	if not _audio_stream_player.get_parent(): add_child(_audio_stream_player)
	
	if not _timer_channels.timeout.is_connected(_on_timer_tick_timeout): _timer_channels.timeout.connect(_on_timer_tick_timeout)

	if not _timer_channels.get_parent(): add_child(_timer_channels)

	if not Engine.is_editor_hint() and auto_play:
		play = true
	pass

func _set_play() -> void:
	_audio_stream_player.play(_current_start_time)
	pass

func _set_pause() -> void:
	_timer_channels.paused = true
	_audio_stream_player.stream_paused = true
	pass

func _set_contin() -> void:
	_timer_channels.paused = false
	_audio_stream_player.stream_paused = false
	pass

func _set_stop() -> void:
	_timer_channels.stop()
	_audio_stream_player.stop()
	pass

func _play_with_out_channels() -> void:
	_timer_channels.stop()
	_current_start_time = 0.0
	_current_end_time = audio_stream.get_length()
	_current_duration = (_current_end_time - _current_start_time) / pitch_scale
	_set_play()
	pass
	
func _play_with_channels() -> void:
	_timer_channels.stop()
	_current_channel_index = 0
	_play_current_channel(_current_channel_index)
	pass

func _play_alternate_channel_by_play() -> void:
	_timer_channels.stop()

	if _current_channel_index >= audio_channels.size():
		_current_channel_index = 0
		
	_play_current_channel(_current_channel_index)
	pass

func _play_current_channel(index: int) -> void:
	if not audio_channels:
		push_warning("You have to create a channel first, before playing the sound")
		if play: play = false
		return

	if audio_channels.size() == 0:
		push_warning("The use_channel property is set to true but there are no channels created")
		if play: play = false
		return
	
	if not audio_channels[index]:
		push_warning("You have to create a channel first, before playing the sound")
		if play: play = false
		return

	_current_start_time = audio_channels[index].start_time
	_current_end_time = audio_channels[index].end_time
	_current_duration = (_current_end_time - _current_start_time) / pitch_scale

	if _current_duration <= 0:
		push_warning("The time duration on the channel cannot be zero. Assign a value to start_time and end_time that does not give zero or less to the duration of the trimmed audio")
		if play: play = false
		return

	_timer_channels.stop()
	_timer_channels.wait_time = _current_duration
	_set_play()
	_timer_channels.start()

	if not alternate_channel_by_play:
		_current_channel_index += 1
	
	pass

func _on_timer_tick_timeout() -> void:
	_set_stop()
	if alternate_channel_by_play:
		if play:
				play = false
		return

	if _current_channel_index >= audio_channels.size():
		if loop:
			_current_channel_index = 0
			_play_current_channel(_current_channel_index)
		else:
			if play:
				play = false
	else:
		_play_current_channel(_current_channel_index)
	pass

func _on_audio_stream_player_finished() -> void:
	if play: play = false
	pass

func _on_audio_stream_player_tree_entered() -> void:
	_can_playing = true
	pass
	
func _on_audio_stream_player_tree_exited() -> void:
	_can_playing = false
	if _audio_stream_player:
		if _audio_stream_player.get_parent():
			remove_child.call_deferred(_audio_stream_player)
	pass

func _on_audio_stream_player_ready() -> void:
	var timer = get_tree().create_timer(0.01)
	timer.timeout.connect(Callable(func():
		if not use_channels and audio_stream:
			_current_duration = audio_stream.get_length() / pitch_scale
			_current_start_time = 0.0
			_current_end_time = _current_duration
		))
	pass

func _audio_stream_player_initializer() -> void:
	_audio_stream_player.stream = audio_stream
	_audio_stream_player.volume_db = volume_db
	_audio_stream_player.max_db = max_db
	_audio_stream_player.unit_size = unit_size
	_audio_stream_player.pitch_scale = pitch_scale
	if not use_channels: _audio_stream_player.autoplay = auto_play
	_audio_stream_player.panning_strength = panning_strength
	_audio_stream_player.max_polyphony = max_polyphony
	_audio_stream_player.attenuation_model = attenuation_model
	_audio_stream_player.max_distance = max_distance
	_audio_stream_player.emission_angle_enabled = emission_angle_enabled
	_audio_stream_player.emission_angle_degrees = emission_angle_degrees
	_audio_stream_player.emission_angle_filter_attenuation_db = emission_angle_filter_attenuation_db
	_audio_stream_player.attenuation_filter_cutoff_hz = attenuation_filter_cutoff_hz
	_audio_stream_player.attenuation_filter_db = attenuation_filter_dbattenuation_filter_db
	_audio_stream_player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	_audio_stream_player.area_mask = area_mask
	
	if not _audio_stream_player.tree_entered.is_connected(_on_audio_stream_player_tree_entered):
		_audio_stream_player.tree_entered.connect(_on_audio_stream_player_tree_entered)
		
	if not _audio_stream_player.tree_exited.is_connected(_on_audio_stream_player_tree_exited):
		_audio_stream_player.tree_exited.connect(_on_audio_stream_player_tree_exited)
	
	if not _audio_stream_player.ready.is_connected(_on_audio_stream_player_ready):
		_audio_stream_player.ready.connect(_on_audio_stream_player_ready)

	if Engine.is_editor_hint():
		if not _audio_stream_player.finished.is_connected(_on_audio_stream_player_finished):
			_audio_stream_player.finished.connect(_on_audio_stream_player_finished)
	pass

func _audio_stream_initializer() -> void:
	_audio_stream_player.stream = audio_stream
	if not (audio_stream is AudioStreamMP3 or audio_stream is AudioStreamMicrophone or audio_stream is AudioStreamRandomizer or audio_stream is AudioStreamPolyphonic or audio_stream is AudioStreamOggVorbis):
		loop = false

	if audio_stream:
		if not use_channels:
			_current_duration = audio_stream.get_length() / pitch_scale
			_current_start_time = 0.0
			_current_end_time = _current_duration
	else:
		if play: play = false
		if pause: pause = false
		_set_stop()
	pass
