extends Node3D

var test_box_scene=load("res://assets/tscn/text_box.tscn")

var master
var _name
var camera
var recoil
var in_hand=false

@export var bullet_scene:PackedScene;

@export var durable=1;
@export var speed=200;
@export var range=10000;
@export var power=20;
@export var magazine_capacity=7;
@export var switch_time=3.0;
@export var fire_time=0.1;

#0-点射 1-全自动 2-点射(瞄准)
@export var mode=0;
#0-无 1-狙击镜
@export var aim_mode=0;

var now_magazine=0;
var switch_frame=0;
var fire_frame=0;
var pre_fire=false;
var in_switch=false;
var in_aim=false;

# Called when the node enters the scene tree for the first time.
func _ready():
	_name=name;
	camera=master.get_node("Camera3D");
	recoil=get_node("recoil");
	recoil.master=master;
	now_magazine=magazine_capacity;
	pass # Replace with function body.
	
func _process(delta):
	if master.get_multiplayer_authority()==multiplayer.get_unique_id():
		if master.hand.in_hand==self:
			inertia();
			pass

func _physics_process(delta):
	if master.get_multiplayer_authority()==multiplayer.get_unique_id():
		if master.hand.in_hand==self:
			if master.state=="normal" and !master.in_menu:
				if switch_frame==0:
					if in_switch:
						in_switch=false;
						now_magazine=magazine_capacity;
					#开火
					if mode==0:
						if (Input.is_action_just_pressed("fire") or pre_fire):
							if now_magazine>0:
								if fire_frame>0:
									pre_fire=true;
								else:
									fire.rpc();
									now_magazine-=1;
									fire_frame=60*fire_time;
									pre_fire=false;
									in_aim=false;
					if mode==1:
						if Input.is_action_pressed("fire"):
							if now_magazine>0:
								if fire_frame==0:
									fire.rpc();
									now_magazine-=1;
									fire_frame=60*fire_time;
									pre_fire=false;
									in_aim=false;
					if mode==2:
						if Input.is_action_pressed("fire"):
							if now_magazine>0:
								if fire_frame==0:
									if !in_aim:
										fire_no_aim.rpc();
										now_magazine-=1;
										fire_frame=60*fire_time;
										pre_fire=false;
										in_aim=false;
									else:
										fire.rpc();
										now_magazine-=1;
										fire_frame=60*fire_time;
										pre_fire=false;
										in_aim=false;
					if Input.is_action_just_pressed("switch") and now_magazine<magazine_capacity:
						switch_frame=60*switch_time;
						in_switch=true;
						in_aim=false;
					if aim_mode==0:
						pass;
					if aim_mode==1:
						if Input.is_action_just_pressed("aim") and fire_frame==0:
							if in_aim:in_aim=false;
							else:in_aim=true;
						pass;
			if fire_frame>0:fire_frame-=1;
			if switch_frame>0:switch_frame-=1;
	pass

@rpc("any_peer","call_local")
func fire():
	var b=bullet_scene.instantiate();
	b.start_position=camera.global_position;
	b.global_position=camera.global_position;
	#后座力偏移量
	var recoil_position=recoil.position;
	var recoil_rotation=Vector3();
	recoil_rotation.y=atan(recoil_position.x/recoil_position.z);
	recoil_rotation.x=(atan(recoil_position.y/sqrt(pow(recoil_position.z,2)+pow(recoil_position.x,2))));
	b.fly_rotation=camera.global_rotation+recoil_rotation;
	b.master=str(master.get_multiplayer_authority());
	b.name="bullet_"+str(master.get_multiplayer_authority());
	b.durable=durable;
	b.speed=speed;
	b.range=range;
	b.power=power;
	get_tree().root.add_child(b);
	recoil.fire();
	if mode==1:
		master.get_node("Camera3D").rotation+=recoil_rotation*0.2;
		
@rpc("any_peer","call_local")
func fire_no_aim():
	var b=bullet_scene.instantiate();
	b.start_position=camera.global_position;
	b.global_position=camera.global_position;
	#后座力偏移量
	recoil.fire();
	var recoil_position=recoil.position;
	var recoil_rotation=Vector3();
	recoil_rotation.y=atan(recoil_position.x/recoil_position.z);
	recoil_rotation.x=(atan(recoil_position.y/sqrt(pow(recoil_position.z,2)+pow(recoil_position.x,2))));
	b.fly_rotation=camera.global_rotation+recoil_rotation;
	b.master=str(master.get_multiplayer_authority());
	b.name="bullet_"+str(master.get_multiplayer_authority());
	b.durable=durable;
	b.speed=speed;
	b.range=range;
	b.power=power;
	get_tree().root.add_child(b);
	if mode==1:
		master.get_node("Camera3D").rotation+=recoil_rotation*0.2;

func relive():
	now_magazine=magazine_capacity;
	switch_frame=0;
	fire_frame=0;
	pre_fire=false;
	in_switch=false;
	
func switch():
	switch_frame=0;
	pre_fire=false;
	in_switch=false;
	
func inertia():
	#枪械惯性
	var max=0.005;
	var speed=0.1;
	var mouse_delta_last=master.mouse_delta_last;
	if mouse_delta_last.length()>max:
		mouse_delta_last.normalized()
		mouse_delta_last*=max;
	var position_vec3=Vector3();
	position_vec3=$gun.position;
	var mouse_delta_vec3=Vector3();
	mouse_delta_vec3.x=mouse_delta_last.x;
	mouse_delta_vec3.y=mouse_delta_last.y;
	var diff_vec3=mouse_delta_vec3-position_vec3;
	diff_vec3.normalized();
	diff_vec3*=speed;
	position_vec3+=diff_vec3;
	if position_vec3.length()>max and false:
		position_vec3.normalized();
		position_vec3*=max;
	$gun.position=position_vec3;
