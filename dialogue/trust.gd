extends Node

# Accumulated trust toward the two voices. 0 = neutral.
var guide := 0
var stranger := 0

const GUIDE_SURRENDER := 3   # followed the Guide unquestioningly
const LOW := 1               # effectively trusted no one

func add_guide(v: int) -> void:
	guide += v

func add_stranger(v: int) -> void:
	stranger += v

func reset() -> void:
	guide = 0
	stranger = 0

# Returns "void" | "trust" | "distrust" | "balanced"
# "void" = allied with Dr. Void at any point (the secret path)
func evaluate() -> String:
	if Flags.has_flag("void_ally"):
		return "void"
	if guide >= 5 and guide >= stranger + 2:
		return "trust"
	if stranger >= 5 and stranger >= guide + 2:
		return "distrust"
	return "balanced"
