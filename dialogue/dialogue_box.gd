extends Control

signal line_advanced
signal choice_selected(index: int)

@onready var speaker_lbl: Label = $Box/Speaker
@onready var text_lbl: Label = $Box/Text
@onready var choices_box: VBoxContainer = $Box/Choices
@onready var accent: ColorRect = $Box/Accent

var _full := ""
var _shown := 0.0
var _speed := 55.0
var _is_choice := false
var _ending := false
var _jester := false

func _ready() -> void:
	hide()
	choices_box.hide()

func show_line(spk: String, style: String, text: String, ending: bool) -> void:
	visible = true
	_is_choice = false
	_ending = ending
	_jester = false
	choices_box.hide()
	_full = text
	_shown = 0.0
	text_lbl.text = ""
	speaker_lbl.text = spk
	_style(style, spk)

func _style(style: String, spk: String) -> void:
	var col := _speaker_color(spk)
	speaker_lbl.modulate = col
	accent.visible = true
	accent.color = col
	speaker_lbl.visible = spk != ""
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	match style:
		"narrative":
			speaker_lbl.visible = false
			accent.visible = false
			text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			text_lbl.modulate = Color(0.82, 0.82, 0.85)
		"jester":
			_jester = true
			text_lbl.modulate = Color(1.0, 0.45, 0.9)
		"reveal":
			text_lbl.modulate = Color(0.55, 1.0, 1.0)
		"system":
			speaker_lbl.visible = false
			accent.visible = false
			text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			text_lbl.modulate = Color(0.4, 1.0, 0.55)
		"thought":
			text_lbl.modulate = Color(0.75, 0.9, 1.0)
		"inscription":
			text_lbl.modulate = Color(1.0, 0.85, 0.55)
		"void":
			text_lbl.modulate = Color(0.9, 0.9, 0.95)
		_:
			text_lbl.modulate = Color(1.0, 1.0, 1.0)

func _speaker_color(spk: String) -> Color:
	match spk:
		"Guide": return Color(0.5, 1.0, 0.6)
		"Stranger": return Color(0.6, 0.8, 1.0)
		"Dr. Void": return Color(1.0, 0.45, 0.9)
		"Dr. Arden": return Color(0.55, 1.0, 1.0)
		"Mark": return Color(1.0, 1.0, 1.0)
		_: return Color(0.85, 0.85, 0.85)

func show_choices(options: Array, prompt: String = "") -> void:
	visible = true
	_is_choice = true
	_jester = false
	if prompt != "":
		text_lbl.text = prompt
		text_lbl.visible = true
		speaker_lbl.text = "CORE TRIAL"
		speaker_lbl.visible = true
		accent.visible = true
		accent.color = Color(1.0, 0.45, 0.9)
		text_lbl.modulate = Color(0.9, 0.9, 0.95)
	_choices_prompt = prompt
	choices_box.show()
	for c in choices_box.get_children():
		c.queue_free()
	for i in range(options.size()):
		var b := Button.new()
		b.text = "  [%d]  %s" % [i + 1, options[i]]
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85))
		b.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0))
		b.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0))
		b.add_theme_stylebox_override("normal", _choice_style(Color(0.10, 0.12, 0.16, 0.95), Color(1.0, 0.45, 0.9)))
		b.add_theme_stylebox_override("hover", _choice_style(Color(1.0, 0.45, 0.9, 0.95), Color(1.0, 1.0, 1.0)))
		b.add_theme_stylebox_override("pressed", _choice_style(Color(0.85, 0.3, 0.7, 1.0), Color(1.0, 1.0, 1.0)))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.custom_minimum_size = Vector2(0, 40)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.connect("pressed", _on_choice.bind(i))
		choices_box.add_child(b)

var _choices_prompt := ""

func _choice_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb

func _on_choice(i: int) -> void:
	emit_signal("choice_selected", i)

func advance() -> void:
	if _is_choice:
		return
	if _shown < _full.length():
		_shown = _full.length()
		text_lbl.text = _full
	else:
		emit_signal("line_advanced")

func _gui_input(event: InputEvent) -> void:
	if _is_choice:
		if event is InputEventKey and event.pressed and not event.echo:
			var key: InputEventKey = event
			var kc: int = key.keycode
			if kc >= KEY_1 and kc <= KEY_9:
				var idx := kc - KEY_1
				var count := choices_box.get_child_count()
				if idx < count:
					_on_choice(idx)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()

func _process(delta: float) -> void:
	if _is_choice:
		return
	if _jester and visible:
		text_lbl.modulate = Color(1.0, 0.45, 0.9).lerp(Color(randf(), randf(), randf()), 0.18)
	if _shown < _full.length():
		_shown += _speed * delta
		text_lbl.text = _full.substr(0, int(_shown))
