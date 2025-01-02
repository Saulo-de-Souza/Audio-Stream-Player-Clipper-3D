@tool
extends EditorPlugin

var icon = preload("res://addons/audio_stream_player_clipper_3d/images/icon-16x16.png")
var custom_script = preload("res://addons/audio_stream_player_clipper_3d/scripts/audio_stream_player_clipper_3d.gd")
var script_resource_channel = preload("res://addons/audio_stream_player_clipper_3d/scripts/channel.gd")

func _enter_tree() -> void:
	add_custom_type("AudioStreamPlayerClipper3D", "Node3D", custom_script, icon)
	add_custom_type("Channel", "Resource", script_resource_channel, null)
	pass


func _exit_tree() -> void:
	remove_custom_type("AudioStreamPlayerClipper3D")
	remove_custom_type("Channel")
	pass
