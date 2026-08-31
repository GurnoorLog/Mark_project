extends Node

# Records consequential choices made during dialogue so endings can branch
# on the whole pattern of a playthrough, not just the final pick.
var data := {}

func set_flag(k: String, v: Variant = true) -> void:
	data[k] = v

func has_flag(k: String) -> bool:
	return data.has(k)

func get_flag(k: String, default: Variant = null) -> Variant:
	return data.get(k, default)

func clear() -> void:
	data.clear()
