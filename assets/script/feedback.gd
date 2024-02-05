extends Label

func _ready():
	modulate.a=0;

func _physics_process(delta):
	if modulate.a>0:
		modulate.a-=(1.0/60);
	pass

func update(info):
	text=info;
	modulate.a=1;
