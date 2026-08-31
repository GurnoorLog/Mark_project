extends Node

signal changed

var collected := 0
var total := 0

func register() -> void:
	total += 1
	changed.emit()

func grab() -> void:
	collected += 1
	changed.emit()

func all_done() -> bool:
	return total > 0 and collected >= total

func reset() -> void:
	collected = 0
	total = 0
	changed.emit()
