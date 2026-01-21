@tool
extends MeshInstance3D
class_name ChunkNode

@export var chunk_size := 16
@export var chunk_coord := Vector3i.ZERO
@export var atlas_texture: Texture2D


var world: World
var chunk: Chunk
var regenerate := false
var mesher: ChunkMesher
var terrain_generator: TerrainGenerator
var chunk_mesh := ChunkMesh.new()
var array_mesh := ArrayMesh.new()
var material: StandardMaterial3D

func _ready() -> void:
	mesher = ChunkMesher.new()
	material = StandardMaterial3D.new()
	material.albedo_texture = atlas_texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	position = Vector3(
		chunk_coord.x * chunk_size,
		chunk_coord.y * chunk_size,
		chunk_coord.z * chunk_size
	)
	
	regenerate = true

func _process(_delta) -> void:
	if regenerate:
		chunk = Chunk.new(chunk_size)
		terrain_generator.generate(chunk, chunk_coord)
		
		mesher.build(chunk, chunk_mesh, world, chunk_coord)
		
		build_mesh()
		regenerate = false

func build_mesh() -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = chunk_mesh.vertices
	arrays[Mesh.ARRAY_INDEX] = chunk_mesh.indices
	arrays[Mesh.ARRAY_TEX_UV] = chunk_mesh.uvs

	mesh = null
	array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_material(0, material)
	mesh = array_mesh
	chunk_mesh.clear()
