extends Node2D

const INTERACTABLE := preload("res://dialogue/interactable.tscn")

# Each entry: x position, dialogue id, prompt text
const SPECS := [
	[-1700, "a1_open", "[E] Examine the radio"],
	[-1300, "a1_photos", "[E] Look at the photographs"],
	[-900, "a2_man1", "[E] Talk to the man"],
]

func _ready() -> void:
	Progress.reset()
	Flags.clear()
	for spec in SPECS:
		var x: float = spec[0]
		var id: String = spec[1]
		var prompt: String = spec[2]
		var i := INTERACTABLE.instantiate()
		i.position = Vector2(x, 560)
		i.dialogue_id = id
		i.prompt_text = prompt
		if id == "a1_open":
			i.glitch_intro = true
			i.massive_after = true
		i.add_to_group("interactable")
		add_child(i)
	DialogueRunner.start("intro")
