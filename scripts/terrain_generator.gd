class_name TerrainGenerator

var noise : FastNoiseLite

func _init(seed: int) -> void:
	noise = FastNoiseLite.new()
	noise.frequency = 0.03
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = seed

func generate(chunk: Chunk, chunk_coords: Vector3i) -> void:
	var max_height := 16
	
	for x in range(chunk.size):
		for z in range(chunk.size):
			var wx = chunk_coords.x * chunk.size + x
			var wz = chunk_coords.z * chunk.size + z
			var h := noise.get_noise_2d(wx, wz)
			var height := int(((h + 1.0) * 0.5) * max_height)
			
			for y in range(chunk.size):
				chunk.blocks[chunk.block_index(x, y, z)] = (
					Block.SOLID if y <= height else Block.AIR
				)
