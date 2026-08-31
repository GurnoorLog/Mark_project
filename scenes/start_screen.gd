extends Control

static var returned_from_game := false

@onready var title: Label = $Center/VBox/Title
@onready var subtitle: Label = $Center/VBox/Subtitle
@onready var start_btn: Button = $Center/VBox/StartButton
@onready var backdrop: ColorRect = $Backdrop

var _started := false

func _ready() -> void:
	start_btn.pressed.connect(_start_game)
	if returned_from_game:
		title.text = "MARK"
		subtitle.text = "The experiment is over. The tower stands - or falls - on your choices."
		start_btn.text = "Restart the experiment"
	else:
		subtitle.text = "A man built a cathedral to create a soul - and dared to surpass God."
		start_btn.text = "Start the experiment"

func _start_game() -> void:
	if _started:
		return
	_started = true
	returned_from_game = false
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()
