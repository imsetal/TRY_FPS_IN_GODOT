extends Control

var master;
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	master.mouse_speed=$menu/option_menu/sensitivity.value;
	master.mouse_speed_in_aim=$menu/option_menu/sensitivity_in_aim.value;
	pass
