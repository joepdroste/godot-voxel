class_name Chunk

var size: int
var blocks: PackedByteArray

func _init(chunk_size: int) -> void:
	size = chunk_size
	blocks = PackedByteArray()
	blocks.resize(size * size * size)

func block_index(x: int, y: int, z: int) -> int:
	return x + y * size + z * size * size

func in_bounds(x: int, y: int, z: int) -> bool:
	return (
		x >= 0 and x < size and
		y >= 0 and y < size and
		z >= 0 and z < size
	)

func is_solid(x: int, y: int, z: int) -> bool:
	return get_block(x, y, z) == Block.SOLID
	
func get_block(x: int, y: int, z: int) -> int:
	if not in_bounds(x, y, z):
		return Block.AIR
	return blocks[block_index(x, y, z)]
	
func set_block(x: int, y: int, z: int, block_type: int) -> void:
	if not in_bounds(x, y, z):
		return
	blocks[block_index(x, y, z)] = block_type
	
