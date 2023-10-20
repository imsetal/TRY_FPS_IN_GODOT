extends RigidBody3D

@export var test_box:PackedScene;

var master;
var fly_rotation=Vector3();
var start_position=Vector3();
var inArea=false;
var last_position=Vector3();
var first=true;
var hit_list=[];

var durable=1;
var speed=200;
var range=10000;
var power=20;

@onready var self_area=$bullet;

# Called when the node enters the scene tree for the first time.
func _ready():
	last_position=start_position;
	pass # Replace with function body.
	
func _enter_tree():
	last_position=start_position;
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var long=0;
func _physics_process(delta):
	var line=Vector3();
	line.z=-cos(fly_rotation.y);
	line.x=-sin(fly_rotation.y);
	line.y=1*tan(fly_rotation.x);
	line=line.normalized()*speed;
	set_axis_velocity(line);
	long+=speed;
	if(!first):
		offset();
	last_position=global_position;
	first=false;
	if(inArea):
		durable-=1;
	if(durable<=0 or long>range):
		queue_free();

func offset():
	for child in self_area.get_children():
		#print(child.name);
		if child.name!="self":
			child.free();
	var diff_vec3=last_position-global_position;
	var diff_length=diff_vec3.length();
	var shape=self_area.get_node("self").shape;
	var r=0.1;
	var time=int(diff_length/(r*2));
	var a_diff_vec3=diff_vec3/time;
	for i in range(time):
		var coll=CollisionShape3D.new();
		var sphereShape=SphereShape3D.new();
		sphereShape.radius=shape.radius;
		coll.shape=sphereShape;
		coll.name="offset_"+str(i);
		self_area.add_child(coll);
		coll.global_position=global_position+i*a_diff_vec3;
		if i!=time and i!=0 and false:
			var _test_box=test_box.instantiate();
			get_parent().add_child(_test_box);
			_test_box.global_position=coll.global_position;

func _on_bullet_body_entered(body):
	if master!=str(body.name) and !hit_list.has(str(body.name)):
		inArea=true;
		print(master+"射出的子弹击中了:"+str(body.name))
		hit_list.insert(hit_list.size(),str(body.name))
		if body.is_in_group("player") and multiplayer.is_server():
			print(master+"对"+str(body.name)+"造成伤害:"+str(power))
			body.hurt.rpc_id(body.get_multiplayer_authority(),power,master)
	#body.hurt.rpc(power);
	pass # Replace with function body.


func _on_bullet_body_exited(body):
	inArea=false;
	pass # Replace with function body.
