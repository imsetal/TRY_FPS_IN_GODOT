extends Camera3D

@onready var hand=$Hand
var state="";
var follow_obj:Node3D;
var follow_frame=0;
var camera_pos_obj:Node3D;

# Called when the node enters the scene tree for the first time.
func _ready():
	if(is_multiplayer_authority()):
		var Body=get_node("../Body");
		Body.visible=false;
		$Control.visible=true;
	else:
		var Body=get_node("../Body");
		Body.visible=true;
		$Control.visible=false;
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state=="":
		if hand.in_hand_isGun:
			if hand.in_hand.name=="awp":
				$Control/crosshair.hide();
				if hand.in_hand.in_aim:
					$Control/awp_scope.show();
					$Control/crosshair.hide();
					hand.in_hand.hide();
				else:
					$Control/awp_scope.hide();
					$Control/crosshair.show();
					hand.in_hand.show();
				if hand.in_hand.fire_frame>0:
					$Control/in_fire_time.show();
				else:
					$Control/in_fire_time.hide();
			else:
				$Control/awp_scope.hide();
				$Control/crosshair.show();
				$Control/in_fire_time.hide();
				hand.in_hand.show();
		else:
			$Control/awp_scope.hide();
			$Control/crosshair.show();
			$Control/in_fire_time.hide();
	if state=="follow_obj":
		$Control/awp_scope.hide();
		$Control/crosshair.hide();
		$Control/in_fire_time.hide();
		hand.in_hand.hide();
	pass

func _physics_process(delta):
	if $Hand.in_hand_isGun:
		$Control/in_switch.text="换弹中("+str(hand.in_hand.switch_frame)+")";
		$Control/in_fire_time.text="开火冷却("+str(hand.in_hand.fire_frame)+")";
	if state=="follow_obj":
		if follow_frame>0:
			var obj_position=follow_obj.global_position;
			var obj_rotation=follow_obj.global_rotation;
			global_position=global_position+(obj_position-global_position)/follow_frame;
			global_rotation=global_rotation+(obj_rotation-global_rotation)/follow_frame;
			follow_frame-=1;
		else:
			global_position=follow_obj.global_position;
			global_rotation=follow_obj.global_rotation;
		pass

func start_follow_obj(obj,time):
	follow_frame=time*60;
	follow_obj=obj;
	state="follow_obj";
	pass
	
func cancel_follow_obj():
	follow_frame=0;
	state="";
	global_position=camera_pos_obj.global_position;
	global_rotation=camera_pos_obj.global_rotation;
	pass;
