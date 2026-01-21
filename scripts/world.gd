@tool
extends Node3D
class_name World

@export var chunk_size := 16
@export var world_radius := 2
@export var regenerate := false
@export var atlas_texture: Texture2D
@export var world_seed: int = 12345

@onready var chunks_root := get_node_or_null("Chunks")

var terrain_generator: TerrainGenerator
var chunks: Dictionary[Vector3i, ChunkNode] = {}

func _ready():
	if not chunks_root:
		chunks_root = Node3D.new()
		chunks_root.name = "Chunks"
		add_child(chunks_root)
	
	terrain_generator = TerrainGenerator.new(world_seed)
	build_world()

func _process(_delta):
	if regenerate:
		clear_world()
		build_world()
		regenerate = false

func build_world():
	clear_world()
	chunks.clear()
	
	for x in range(-world_radius, world_radius + 1):
		for z in range(-world_radius, world_radius + 1):
			var coord := Vector3i(x, 0, z)
			var chunk := ChunkNode.new()
			chunk.chunk_size = chunk_size
			chunk.chunk_coord = coord
			chunk.world = self
			chunk.atlas_texture = atlas_texture
			chunk.terrain_generator = terrain_generator
			chunks_root.add_child(chunk)
			
func clear_world():
	for c in chunks_root.get_children():
		c.queue_free()
		
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
	
func mark_neighbours_dirty(coord: Vector3i):
	for direction in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		if chunks.has(coord + direction):
			chunks[coord + direction].regenerate = true
