class_name Channel extends Resource

@export_range(0, 20, 0.1, "or_greater", "suffix:sec") var start_time: float = 0.0
@export_range(0, 20, 0.1, "or_greater", "suffix:sec") var end_time: float = 0.0

func _init(_start_time: float = 0.0, _end_time: float = 0.0) -> void:
	start_time = _start_time
	end_time = _end_time
