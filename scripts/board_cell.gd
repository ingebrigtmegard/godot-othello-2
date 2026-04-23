extends Button

class_name BoardCell

signal cell_pressed(x: int, y: int)

var x: int = 0
var y: int = 0

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	cell_pressed.emit(x, y)
