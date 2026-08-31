extends Node

var data := {}
var active := false
var box: Control = null
const BOX_SCENE = preload("res://dialogue/dialogue_box.tscn")

var _pending_next := ""
var _is_choice := false
var _current: Dictionary = {}
var _ending_active := false
var _seq: Array = []
var _seq_idx := -1
var _seq_done: Callable
var _massive_after := false

const GLITCH_INTRO := [
	{"speaker": "", "text": "ENGINE FAILURE.\nRECALIBRATING…\n…no.\nlet's try again.", "style": "system"},
	{"speaker": "Dr. Void", "text": "Did you feel that, Mark? That was me, tugging the rug out from under your world. Don't worry. I'll set it back. For now.", "style": "jester"},
]

func _ready() -> void:
	var f := FileAccess.open("res://dialogue/dialogue_data.json", FileAccess.READ)
	if f == null:
		push_error("DialogueRunner: dialogue_data.json missing")
		return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if parsed != null and parsed.has("nodes"):
		data = parsed["nodes"]
	else:
		push_error("DialogueRunner: failed to parse dialogue_data.json")

func start(id: String, glitch_intro: bool = false, massive_after: bool = false) -> void:
	if active:
		return
	if not data.has(id):
		push_error("DialogueRunner: no node " + id)
		return
	if box == null or not is_instance_valid(box) or box.get_parent() == null:
		box = BOX_SCENE.instantiate()
		var cl := CanvasLayer.new()
		cl.layer = 150
		cl.add_child(box)
		get_tree().root.add_child(cl)
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.line_advanced.connect(_on_line_advanced)
		box.choice_selected.connect(_on_choice)
	active = true
	_massive_after = massive_after
	if glitch_intro:
		Void.enter()
		_play_sequence(GLITCH_INTRO, func(): _goto(id))
	else:
		box.show()
		_goto(id)

func _play_sequence(seq: Array, on_done: Callable) -> void:
	_seq = seq
	_seq_idx = -1
	_seq_done = on_done
	box.show()
	_next_in_seq()

func _next_in_seq() -> void:
	_seq_idx += 1
	if _seq_idx >= _seq.size():
		_seq = []
		var cb = _seq_done
		_seq_done = Callable()
		if cb.is_valid():
			cb.call()
		return
	var n: Dictionary = _seq[_seq_idx]
	_apply_void(n.get("style", "dialogue"))
	box.show_line(n.get("speaker", ""), n.get("style", "dialogue"), n.get("text", ""), false)

func _goto(id: String) -> void:
	if not data.has(id):
		finish()
		return
	var n: Dictionary = data[id]
	if n.get("type") == "glitch":
		Void.enter()
		_play_sequence([{"speaker": n.get("speaker", ""), "text": n.get("text", ""), "style": n.get("style", "system")}], func(): _goto(n.get("next", "")))
		return
	if n.get("type") == "decision":
		var end := "ending_" + Trust.evaluate()
		if data.has(end):
			n = data[end]
		else:
			finish()
			return
	_is_choice = n.has("choices")
	if _is_choice:
		_current = n
		_apply_void(n.get("style", "dialogue"))
		var opts := []
		for c in n["choices"]:
			opts.append(c.get("label", ""))
		box.show_choices(opts, n.get("prompt", ""))
		_pending_next = ""
	else:
		_current = {}
		var spk: String = n.get("speaker", "")
		var style: String = n.get("style", "dialogue")
		var txt: String = n.get("text", "")
		var ending: bool = n.get("type") == "ending"
		_ending_active = ending
		_apply_void(style)
		if n.has("trust_guide"):
			Trust.add_guide(int(n["trust_guide"]))
		if n.has("trust_stranger"):
			Trust.add_stranger(int(n["trust_stranger"]))
		if n.has("flag"):
			Flags.set_flag(String(n["flag"]), true)
		box.show_line(spk, style, txt, ending)
		_pending_next = n.get("next", "")

func _apply_void(style: String) -> void:
	var void_styles := ["jester", "void", "reveal", "system"]
	if style in void_styles:
		Void.enter()
	else:
		Void.exit()

func _on_line_advanced() -> void:
	if _seq.size() > 0:
		_next_in_seq()
		return
	if _pending_next != "" and data.has(_pending_next):
		_goto(_pending_next)
	else:
		finish()

func _on_choice(idx: int) -> void:
	if _current.is_empty() or not _current.has("choices"):
		return
	var c: Dictionary = _current["choices"][idx]
	if c.has("trust_guide"):
		Trust.add_guide(int(c["trust_guide"]))
	if c.has("trust_stranger"):
		Trust.add_stranger(int(c["trust_stranger"]))
	if c.has("flag"):
		Flags.set_flag(String(c["flag"]), true)
	var nx: String = c.get("next", "")
	_current = {}
	_seq = []
	if nx != "" and data.has(nx):
		_goto(nx)
	else:
		finish()

func finish() -> void:
	active = false
	_is_choice = false
	_seq = []
	var was_massive = _massive_after
	_massive_after = false
	if was_massive:
		Glitch.trigger(true)
	else:
		if box != null:
			box.hide()
		Void.exit()
	if _ending_active:
		_ending_active = false
		Trust.reset()
		Flags.clear()
		var ss := load("res://scenes/start_screen.gd")
		if ss != null:
			ss.returned_from_game = true
		get_tree().change_scene_to_file("res://scenes/start_screen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not active or _is_choice:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_ENTER:
			box.advance()
