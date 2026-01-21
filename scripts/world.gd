extends Node3D
class_name World

@export var chunk_size := 16
@export var render_distance := 4
@export var atlas_texture: Texture2D
@export var world_seed: int = 12345
@export var chunks_per_frame := 4  # How many chunks to generate per frame

var terrain_generator: TerrainGenerator
var chunks: Dictionary = {}
var last_player_chunk := Vector3i(999999, 999999, 999999)
var chunk_queue: Array[Vector3i] = []  # Chunks waiting to be created
var is_generating := false
var initial_load_complete := false

func _ready():
	terrain_generator = TerrainGenerator.new(world_seed)

func _process(_delta):
	# Process chunk queue
	if chunk_queue.size() > 0:
		is_generating = true
		var chunks_this_frame = min(chunks_per_frame, chunk_queue.size())
		
		for i in range(chunks_this_frame):
			var coord = chunk_queue.pop_front()
			create_chunk(coord)
		
		# Check if initial load is complete
		if chunk_queue.size() == 0:
			is_generating = false
			if not initial_load_complete:
				initial_load_complete = true
				print("Initial chunk generation complete!")
	else:
		is_generating = false

func update_chunks_around_player(player_pos: Vector3):
	# Get chunk coordinates of player
	var player_chunk := Vector3i(
		floori(player_pos.x / chunk_size),
		floori(player_pos.y / chunk_size),
		floori(player_pos.z / chunk_size)
	)
	
	# Only update if player moved to a different chunk
	if player_chunk == last_player_chunk:
		return
	
	last_player_chunk = player_chunk
	
	# Determine which chunks should exist
	var chunks_to_keep := {}
	var new_chunks: Array[Vector3i] = []
	
	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for y in range(player_chunk.y - 1, player_chunk.y + 2):
			for z in range(player_chunk.z - render_distance, player_chunk.z + render_distance + 1):
				var coord := Vector3i(x, y, z)
				chunks_to_keep[coord] = true
				
				# Add to queue if it doesn't exist
				if not chunks.has(coord) and not chunk_queue.has(coord):
					new_chunks.append(coord)
	
	# Sort new chunks by distance to player (closest first)
	new_chunks.sort_custom(func(a, b): 
		var dist_a = (a - player_chunk).length_squared()
		var dist_b = (b - player_chunk).length_squared()
		return dist_a < dist_b
	)
	
	# Add to queue
	for coord in new_chunks:
		chunk_queue.append(coord)
	
	# Remove chunks that are too far away
	var chunks_to_remove := []
	for coord in chunks.keys():
		if not chunks_to_keep.has(coord):
			chunks_to_remove.append(coord)
	
	for coord in chunks_to_remove:
		remove_chunk(coord)

func create_chunk(coord: Vector3i):
	var chunk := ChunkNode.new()
	chunk.chunk_size = chunk_size
	chunk.chunk_coord = coord
	chunk.world = self
	chunk.atlas_texture = atlas_texture
	chunk.terrain_generator = terrain_generator
	add_child(chunk)
	chunks[coord] = chunk

func remove_chunk(coord: Vector3i):
	if chunks.has(coord):
		var chunk = chunks[coord]
		chunks.erase(coord)
		chunk.queue_free()

func is_solid(wx: int, wy: int, wz: int) -> bool:
	var cx := floori(float(wx) / chunk_size)
	var cy := floori(float(wy) / chunk_size)
	var cz := floori(float(wz) / chunk_size)
	
	var chunk_coord := Vector3i(cx, cy, cz)
	
	if not chunks.has(chunk_coord):
		return false
	
	var chunk_node: ChunkNode = chunks[chunk_coord]
	if chunk_node.chunk == null:
		return false
		
	var lx := wx - cx * chunk_size
	var ly := wy - cy * chunk_size
	var lz := wz - cz * chunk_size
	
	return chunk_node.chunk.is_solid(lx, ly, lz)
