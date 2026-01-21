class_name TerrainGenerator

var noise : FastNoiseLite

func _init(seed_value: int) -> void:
	noise = FastNoiseLite.new()
	noise.frequency = 0.02
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = seed_value

func generate(chunk: Chunk, chunk_coords: Vector3i) -> void:
	var base_height := 48
	
	for x in range(chunk.size):
		for z in range(chunk.size):
			var wx = chunk_coords.x * chunk.size + x
			var wz = chunk_coords.z * chunk.size + z
			var h := noise.get_noise_2d(wx, wz)
			var height := int(((h + 1.0) * 0.5) * 32) + 32
			
			for y in range(chunk.size):
				var wy = chunk_coords.y * chunk.size + y
				
				if wy <= height:
					chunk.blocks[chunk.block_index(x, y, z)] = Block.SOLID
				else:
					chunk.blocks[chunk.block_index(x, y, z)] = Block.AIR
