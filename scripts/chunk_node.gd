extends StaticBody3D
class_name ChunkNode

var chunk_size := 16
var chunk_coord := Vector3i.ZERO
var atlas_texture: Texture2D

var world: World
var chunk: Chunk
var terrain_generated := false
var mesh_built := false
var mesher: ChunkMesher
var terrain_generator: TerrainGenerator
var chunk_mesh := ChunkMesh.new()
var array_mesh := ArrayMesh.new()
var material: StandardMaterial3D

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

var ready_to_mesh := false
var frames_waited := 0

func _ready() -> void:
	# Create mesh instance as child
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	
	mesher = ChunkMesher.new()
	material = StandardMaterial3D.new()
	material.albedo_texture = atlas_texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	position = Vector3(
		chunk_coord.x * chunk_size,
		chunk_coord.y * chunk_size,
		chunk_coord.z * chunk_size
	)
	
	# Generate terrain immediately
	chunk = Chunk.new(chunk_size)
	terrain_generator.generate(chunk, chunk_coord)
	terrain_generated = true

func _process(_delta) -> void:
	# Wait a couple frames for neighbors to generate, then mesh
	if terrain_generated and not mesh_built:
		frames_waited += 1
		
		if frames_waited >= 2:  # Wait 2 frames for neighbors
			# Check if critical neighbors exist (not all, just the ones we touch)
			var can_mesh := true
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					for dz in [-1, 0, 1]:
						if dx == 0 and dy == 0 and dz == 0:
							continue
						# Only wait for directly adjacent neighbors
						if abs(dx) + abs(dy) + abs(dz) > 1:
							continue
						var neighbor_coord := chunk_coord + Vector3i(dx, dy, dz)
						if world.chunks.has(neighbor_coord):
							var neighbor = world.chunks[neighbor_coord]
							if not neighbor.terrain_generated:
								can_mesh = false
								break
			
			if can_mesh:
				mesher.build(chunk, chunk_mesh, world, chunk_coord)
				build_mesh()
				mesh_built = true

func build_mesh() -> void:
	if chunk_mesh.vertices.size() == 0:
		return
		
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = chunk_mesh.vertices
	arrays[Mesh.ARRAY_INDEX] = chunk_mesh.indices
	arrays[Mesh.ARRAY_TEX_UV] = chunk_mesh.uvs

	array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_material(0, material)
	mesh_instance.mesh = array_mesh
	
	# Create collision shape from the mesh
	var concave_shape = array_mesh.create_trimesh_shape()
	collision_shape.shape = concave_shape
	
	chunk_mesh.clear()

func regenerate_mesh() -> void:
	mesh_built = false
	frames_waited = 0
