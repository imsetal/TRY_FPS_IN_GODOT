extends Node3D

#竖直偏移量
@export var vertical=0.4;
#最大竖直偏移量
@export var vertical_max=0.8;
#水平偏移量
@export var horizontal=0.2;
#最大水平偏移量
@export var horizontal_max=0.8;
#回正时间
@export var rotational_time=0.5;
#后坐力模式 0-随机散射 1-向上
@export var mode=0;

var master;
var rotational_frame=0;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotational()
	pass

func rotational():
	if position.x!=0 or position.y!=0:
		position.x-=position.x/rotational_frame;
		position.y-=position.y/rotational_frame;
		rotational_frame-=1;
	if rotational_frame==0:
		position.x=0;
		position.y=0;
		
func fire():
	rotational_frame=60*rotational_time;
	if mode==0:
		position.y=randf_range(-vertical_max,vertical_max);
		position.x=randf_range(-horizontal_max,horizontal_max);
	if mode==1:
		var vertical_new=randf_range(vertical*0.8,vertical);
		print(vertical_new)
		if(position.y+vertical_new>vertical_max):
			position.y=vertical_max;
		else:
			position.y+=vertical_new;
		var horizontal_new=randf_range(-horizontal,horizontal);
		position.x+=horizontal_new;

