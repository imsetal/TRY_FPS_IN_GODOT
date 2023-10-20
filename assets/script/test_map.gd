extends Node3D

@export var PlayerScene : PackedScene

var born_pos_list={}
var index = 0
var world_camera
# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	world_camera=$word_camera
	print(GameManager.Players)
	for i in GameManager.Players:
		if !has_player(str(GameManager.Players[i].id)):
			var currentPlayer = PlayerScene.instantiate()
			currentPlayer.name = str(GameManager.Players[i].id)
			currentPlayer.rules_node=self;
			add_child(currentPlayer)
			print("由"+str(get_multiplayer_authority())+"创建"+currentPlayer.name+" 期望创建:"+str(GameManager.Players[i].id))
			for spawn in get_node("born").get_children():
				if spawn.name == str(index):
					currentPlayer.global_position=spawn.global_position;
					currentPlayer.relive_position=spawn.global_position;
					born_pos_list[index]=spawn.global_position;
					print(born_pos_list)
			index += 1
	pass # Replace with function body.
	
@rpc("any_peer","call_local")
func add_player(id):
	print(str(multiplayer.get_unique_id())+":inGame:"+str(id))
	if has_player(str(id)):return
	var currentPlayer = PlayerScene.instantiate()
	currentPlayer.name = str(id)
	currentPlayer.rules_node=self;
	add_child(currentPlayer)
	if currentPlayer.name.substr(0,1)=="@":
		currentPlayer.free();
		return;
	print("由"+str(get_multiplayer_authority())+"inGame创建"+currentPlayer.name+" 期望创建:"+str(id))
	var _int=randi_range(0,3);
	for spawn in get_node("born").get_children():
		if spawn.name == str(_int):
			currentPlayer.global_position = spawn.global_position
			currentPlayer.relive_position=spawn.global_position;
			born_pos_list[index]=spawn.global_position;
			print(born_pos_list)
	index += 1
	pass
	
@rpc("any_peer","call_local")
func del_player(id):
	var players = get_tree().get_nodes_in_group("player")
	for i in players:
		print(str(get_multiplayer_authority())+"has node:"+i.name)
		if i.name == str(id):
			i.queue_free()
	pass

@rpc("any_peer","call_local")
func player_relive(player_id):
	if has_player(str(player_id)):
		var _int=randi_range(0,3);
		get_node(str(player_id)).relive.rpc_id(player_id,get_node("born/"+str(_int)).global_position);

func has_player(_name):
	for c in self.get_children():
		if(c.name==_name):
			return true
	return false;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# this get called on the server and clients
func peer_connected(id):
	print("inGame:Player Connected " + str(id))
	add_player.rpc(id)
	
# this get called on the server and clients
func peer_disconnected(id):
	print("inGame:Player Disconnected " + str(id))
	GameManager.Players.erase(id)
	del_player(id)

# called only from clients
func connected_to_server():
	print("inGame:connected To Sever!")
	#SendPlayerInformation.rpc_id(1, $name_Label/name.text, multiplayer.get_unique_id())

# called only from clients
func connection_failed():
	print("inGame:Couldnt Connect")
	get_tree().change_scene_to_file("res://assets/tscn/multiplayerScene.tscn");
