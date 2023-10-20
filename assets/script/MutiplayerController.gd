extends Control

@export var Address = "127.0.0.1"
@export var port = 9285
var peer

var map="junjie_map"
var map_list={
	"junjie_map":"res://assets/map/junjie_map.tscn"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		hostGame()
	
	for map in map_list:
		$map_OptionButton.add_item(map);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	map=$map_OptionButton.get_item_text($map_OptionButton.get_selected_id())
	#print(map)
	pass

# this get called on the server and clients
func peer_connected(id):
	print("Player Connected " + str(id))
	
# this get called on the server and clients
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()

# called only from clients
func connected_to_server():
	print("connected To Sever!")
	SendPlayerInformation.rpc_id(1, $name_Label/name.text, multiplayer.get_unique_id())

# called only from clients
func connection_failed():
	print("Couldnt Connect")
	get_tree().change_scene_to_file("res://assets/tscn/multiplayerScene.tscn");
	self.hide()

@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] ={
			"name" : name,
			"id" : id,
			"score": 0
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)

@rpc("any_peer","call_local")
func StartGame(_map):
	get_tree().change_scene_to_file(map_list[_map]);
	self.hide()
	
func hostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 32)
	if error != OK:
		print("cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")
	
	
func _on_host_button_down():
	hostGame()
	SendPlayerInformation($name_Label/name.text, multiplayer.get_unique_id())
	StartGame.rpc(map)
	pass # Replace with function body.


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	var error=peer.create_client($Join/Address.text, $Join/Port.text.to_int())
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)	
	StartGame(map);
	pass # Replace with function body.


func _on_start_game_button_down():
	StartGame.rpc()
	pass # Replace with function body.
