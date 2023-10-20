extends Node3D

var peer=ENetMultiplayerPeer.new();
@export var player_scene:PackedScene;
var isHost=false;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _add_player(id=1):
	create_player(id,$born.position);
	
func create_player(id,_position):
	var Player=player_scene.instantiate();
	Player.name=str(id);
	Player.position=_position;
	#Player.born_position=_position;
	if(id==1):
		Player.isHost=true;
	print(Player.name);
	add_child(Player);

func _on_button_pressed():
	peer.create_server(9285);
	multiplayer.multiplayer_peer=peer;
	multiplayer.peer_connected.connect(_add_player);
	_add_player();
	$Control.hide();
	pass # Replace with function body.

func _on_button_2_pressed():
	var address=get_node("Control/address").text;
	var port=get_node("Control/port").text.to_int();
	print(address)
	peer.create_client(address,port);
	multiplayer.multiplayer_peer=peer;
	$Control.hide();
	pass # Replace with function body.
