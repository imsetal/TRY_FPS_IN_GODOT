extends CharacterBody3D

var in_menu=false;

var mouse_speed=1;
var mouse_speed_in_aim=1;
var mouse_delta = Vector2();
var mouse_delta_last = Vector2();
var rules_node;
var relive_position;
var camera;
@export var bullet_scene:PackedScene;
@export var pistol_scene:PackedScene;
@export var ak47_scene:PackedScene;
@export var awp_scene:PackedScene;
var gun_instantiate_list={}

var HP=100;
var state="normal";
@export var jump_time=2;
@export var move_speed=5.0;
@export var move_speed_in_aim=1.0;
var in_jump_time=0;
var in_air_frame=0;

@onready var hand=$Camera3D/Hand;

var materiel_list={
	1:"ak47",
	2:"pistol"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$Camera3D/Control.master=self;
	#初始化枪械列表
	var pistol=pistol_scene.instantiate()
	pistol.name="pistol";
	pistol.master=self;
	pistol.add_to_group("gun");
	gun_instantiate_list["pistol"]=pistol;
	var ak47=ak47_scene.instantiate()
	ak47.name="ak47";
	ak47.master=self;
	ak47.add_to_group("gun");
	gun_instantiate_list["ak47"]=ak47;
	var awp=awp_scene.instantiate()
	awp.name="awp";
	awp.master=self;
	awp.add_to_group("gun");
	gun_instantiate_list["awp"]=awp;
	
	for gun in gun_instantiate_list:
		hand.add_child(gun_instantiate_list[gun])
		gun_instantiate_list[gun].hide()
	
	camera=$Camera3D;
	camera.camera_pos_obj=$camera_pos;
	
	state="in_character_choice";
	pass

func _enter_tree():
	get_node("Camera3D/Control/dead").hide();
	global_position=get_node("../born").position;
	set_multiplayer_authority(name.to_int());
	if(is_multiplayer_authority()):
		$Camera3D.make_current();
	print("player:"+str(name.to_int()));
	add_to_group("player");
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_multiplayer_authority():
		if Input.is_action_just_pressed("menu"):
			if in_menu:in_menu=false;
			else:in_menu=true;
		
		if !in_menu:
			if state=="normal":
				movement();
	#state_check();

func _physics_process(delta):
	if(is_multiplayer_authority()):
		if !in_menu:
			$Camera3D/Control/menu.hide();
			if state=="normal":
				show_mouse(false)
				#movement();
				UI();
				switch();
			if state=="dead":
				show_mouse(true)
				$Camera3D/Control/dead.show();
				UI();
			if state=="in_character_choice":
				$Camera3D/Control/character_choice.show();
				show_mouse(true)
			else:
				$Camera3D/Control/character_choice.hide();
		else:
			show_mouse(true);
			$Camera3D/Control/menu.show();
			$Camera3D/Control/character_choice.hide();
			$Camera3D/Control/dead.hide();
			

			
func switch():
	if Input.is_action_just_pressed("switch_1"):
		switch_gun.rpc(materiel_list[1]);
		hand.in_hand_isGun=true;
	if Input.is_action_just_pressed("switch_2"):
		switch_gun.rpc(materiel_list[2]);
		hand.in_hand_isGun=true;

func movement():
	#鼠标移动
	var _mouse_speed;
	if hand.in_hand.in_aim:
		_mouse_speed=mouse_speed*mouse_speed_in_aim*0.003;
	else:
		_mouse_speed=mouse_speed*0.003;
	rotation.y-=mouse_delta.x*_mouse_speed;
	$Camera3D.rotation.x-=mouse_delta.y*_mouse_speed;
	if($Camera3D.rotation.x>PI/2):
		$Camera3D.rotation.x=PI/2
	if($Camera3D.rotation.x<-PI/2):
		$Camera3D.rotation.x=-PI/2
	mouse_delta_last=mouse_delta;
	mouse_delta.x=0;
	mouse_delta.y=0;
	
	#行走
	var movement=Vector2();
	movement.x=0;movement.y=0;
	if Input.is_action_pressed("move_forward"):
		movement.x+=1;
	if Input.is_action_pressed("move_back"):
		movement.x+=-1;
	if Input.is_action_pressed("move_left"):
		movement.y+=1;
	if Input.is_action_pressed("move_right"):
		movement.y+=-1;
	movement=movement.normalized();
	var target_velocity=Vector3();
	target_velocity=Vector3.ZERO;
	target_velocity.z+=movement.x*cos(rotation.y)-movement.y*sin(rotation.y);
	target_velocity.x+=movement.x*sin(rotation.y)+movement.y*cos(rotation.y);
	if hand.in_hand.in_aim:
		target_velocity*=move_speed_in_aim;
	else:
		target_velocity*=move_speed;
	if(!is_on_floor()):
		in_air_frame+=1;
		target_velocity.y=GravitationalVelocity(in_air_frame);
	else:
		in_air_frame=0;
		in_jump_time=jump_time;
	if(Input.is_action_just_pressed("jump") and in_jump_time>0):
		in_air_frame=-30;
		target_velocity.y=GravitationalVelocity(in_air_frame);
		in_jump_time-=1;
	velocity=target_velocity;
	move_and_slide();

@rpc("any_peer","call_local")
func fire():
	var b=bullet_scene.instantiate();
	b.start_position=$Camera3D.global_position;
	b.global_position=$Camera3D.global_position;
	b.fly_rotation=$Camera3D.global_rotation;
	b.master=str(get_multiplayer_authority());
	b.name="bullet_"+str(get_multiplayer_authority());
	get_tree().root.add_child(b);
	
func UI():
	var hp_laber=get_node("Camera3D/Control/hp");
	hp_laber.text="HP:"+str(HP);
	
	if hand.in_hand.in_switch:
		$Camera3D/Control/in_switch.show()
	else:
		$Camera3D/Control/in_switch.hide()
		
	$Camera3D/Control/now_magazine.text=str(hand.in_hand.now_magazine)

func GravitationalVelocity(frame):
	if(frame<60):
		return (-9.8/60)*frame;
	else:
		return -9.8;

func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta=event.relative;

var num=-1;
func get_num():
	num+=1;
	return num;

@rpc("any_peer","call_local")
func hurt(power,source):
	if state!="normal":return;
	var HP_last=HP;
	HP-=power;
	if HP<=0:
		HP=0;
		die();
		if(has_player(str(source))):
			get_node("../"+str(source)).feedback.rpc_id(source.to_int(),"kill");
	else:
		if(has_player(str(source))):
			get_node("../"+str(source)).feedback.rpc_id(source.to_int(),str(HP_last-HP));
	
@rpc("any_peer","call_local")
func feedback(info):
	print(name+"收到反馈："+info)
	$Camera3D/Control/feedback.update(info);

func die():
	state="dead";
	$CollisionShape3D.disabled=true;
	$Body.position.x=1;
	$Body.position.y=-0.9;
	$Body.rotation.z=-PI/2;

@rpc("any_peer","call_local")
func relive(_position):
	camera.start_follow_obj(rules_node.world_camera,0.8);
	relive_position=_position;
	get_node("Camera3D/Control/dead").hide();
	state="in_character_choice";

@rpc("any_peer","call_local")
func player_relive(_materiel_list):
	$Camera3D/Control/character_choice.hide();
	camera.state="";
	HP=100;
	$CollisionShape3D.disabled=false;
	$Body.position.x=0;
	$Body.position.y=0;
	$Body.rotation.z=0;
	global_position=relive_position;
	state="normal";
	for gun in gun_instantiate_list:
		gun_instantiate_list[gun].relive();
	switch_gun(_materiel_list[1]);
	hand.in_hand_isGun=true;

func has_player(_name):
	for c in get_parent().get_children():
		if(c.name==_name):
			return true
	return false;

func _on_relive_button_pressed():
	rules_node.player_relive.rpc(get_multiplayer_authority())
	pass # Replace with function body.

@rpc("any_peer","call_local")
func switch_gun(gun_name):
	for child in hand.get_children():
		child.hide();
		pass
	hand.get_node(gun_name).show();
	hand.in_hand=hand.get_node(gun_name);
	hand.in_hand.switch();
	pass


func _on_assault_pressed():
	camera.cancel_follow_obj();
	materiel_list={
		1:"ak47",
		2:"pistol"
	}
	player_relive.rpc(materiel_list);
	pass # Replace with function body.

func _on_investigation_pressed():
	camera.cancel_follow_obj();
	materiel_list={
		1:"awp",
		2:"pistol"
	}
	player_relive.rpc(materiel_list);
	pass # Replace with function body.

func show_mouse(_bool):
	if !_bool:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
