class_name ChunkMesher

const ATLAS_SIZE := 4
const TEX_DIV := 1.0 / ATLAS_SIZE

enum Face { TOP, BOTTOM, NORTH, EAST, SOUTH, WEST }

const FACE_TILE := {
	Face.TOP:    Vector2i(0, 0),
	Face.BOTTOM: Vector2i(1, 0),
	Face.NORTH:  Vector2i(2, 0),
	Face.EAST:   Vector2i(3, 0),
	Face.SOUTH:  Vector2i(0, 1),
	Face.WEST:   Vector2i(1, 1),
}

func atlas_uvs(tile_x: int, tile_y: int) -> Array[Vector2]:
	var u0 := tile_x * TEX_DIV
	var v0 := tile_y * TEX_DIV
	var u1 := u0 + TEX_DIV
	var v1 := v0 + TEX_DIV

	return [
		Vector2(u0, v0),
		Vector2(u1, v0),
		Vector2(u1, v1),
		Vector2(u0, v1),
	]
	
func is_solid_world(chunk: Chunk, world: World, chunk_coord: Vector3i, x: int, y: int, z: int) -> bool:
	if chunk.in_bounds(x, y, z):
		return chunk.is_solid(x, y, z)
		
	var wx := chunk_coord.x * chunk.size + x
	var wy := chunk_coord.y * chunk.size + y
	var wz := chunk_coord.z * chunk.size + z
	
	return world.is_solid(wx, wy, wz)
	
	
func _init() -> void:
	pass

func build(chunk: Chunk, out: ChunkMesh, world: World, chunk_coord: Vector3i):
	var uv_face := {}
	for f in FACE_TILE.keys():
		var t: Vector2i = FACE_TILE[f]
		uv_face[f] = atlas_uvs(t.x, t.y) # [uv0, uv1, uv2, uv3]

	var s := chunk.size

	# ------------------------------------------------------------
	# TOP (+Y): plane at y+1, merge in X (width) and Z (depth)
	# ------------------------------------------------------------
	for y in range(s):
		var mask := []
		mask.resize(s)
		for x in range(s):
			mask[x] = []
			mask[x].resize(s)
			for z in range(s):
				mask[x][z] = is_solid_world(chunk, world, chunk_coord, x, y, z) and not is_solid_world(chunk, world, chunk_coord, x, y + 1, z)

		for x in range(s):
			for z in range(s):
				if not mask[x][z]:
					continue

				var width := 1
				while x + width < s and mask[x + width][z]:
					width += 1

				var depth := 1
				while z + depth < s:
					var ok := true
					for i in range(width):
						if not mask[x + i][z + depth]:
							ok = false
							break
					if not ok:
						break
					depth += 1

				for dx in range(width):
					for dz in range(depth):
						mask[x + dx][z + dz] = false

				var y_top := y + 1
				var uv : Array[Vector2] = uv_face[Face.TOP]
				out.add_quad(
					Vector3(x,         y_top, z),
					Vector3(x + width, y_top, z),
					Vector3(x + width, y_top, z + depth),
					Vector3(x,         y_top, z + depth),
					uv[0], uv[1], uv[2], uv[3]
				)

	# ------------------------------------------------------------
	# BOTTOM (-Y): plane at y, merge in X (width) and Z (depth)
	# ------------------------------------------------------------
	for y in range(s):
		var mask := []
		mask.resize(s)
		for x in range(s):
			mask[x] = []
			mask[x].resize(s)
			for z in range(s):
				mask[x][z] = is_solid_world(chunk, world, chunk_coord, x, y, z) and not is_solid_world(chunk, world, chunk_coord, x, y - 1, z)

		for x in range(s):
			for z in range(s):
				if not mask[x][z]:
					continue

				var width := 1
				while x + width < s and mask[x + width][z]:
					width += 1

				var depth := 1
				while z + depth < s:
					var ok := true
					for i in range(width):
						if not mask[x + i][z + depth]:
							ok = false
							break
					if not ok:
						break
					depth += 1

				for dx in range(width):
					for dz in range(depth):
						mask[x + dx][z + dz] = false

				var uv : Array[Vector2] = uv_face[Face.BOTTOM]
				# Matches your original bottom winding:
				# (x,y,z+1) (x+1,y,z+1) (x+1,y,z) (x,y,z)
				out.add_quad(
					Vector3(x,         y, z + depth),
					Vector3(x + width, y, z + depth),
					Vector3(x + width, y, z),
					Vector3(x,         y, z),
					uv[0], uv[1], uv[2], uv[3]
				)

	# ------------------------------------------------------------
	# EAST (+X): plane at x+1, merge in Z (width) and Y (depth)
	# ------------------------------------------------------------
	for x in range(s):
		var mask := []
		mask.resize(s) # u = z
		for z in range(s):
			mask[z] = []
			mask[z].resize(s) # v = y
			for y in range(s):
				mask[z][y] = is_solid_world(chunk, world, chunk_coord, x, y, z) and not is_solid_world(chunk, world, chunk_coord, x + 1, y, z)

		for z in range(s):
			for y in range(s):
				if not mask[z][y]:
					continue

				var width := 1
				while z + width < s and mask[z + width][y]:
					width += 1

				var depth := 1
				while y + depth < s:
					var ok := true
					for i in range(width):
						if not mask[z + i][y + depth]:
							ok = false
							break
					if not ok:
						break
					depth += 1

				for dz in range(width):
					for dy in range(depth):
						mask[z + dz][y + dy] = false

				var uv : Array[Vector2] = uv_face[Face.EAST]
				var x_plane := x + 1
				# Matches your original east winding:
				# (x+1,y+1,z+1) (x+1,y+1,z) (x+1,y,z) (x+1,y,z+1)
				out.add_quad(
					Vector3(x_plane, y + depth, z + width),
					Vector3(x_plane, y + depth, z),
					Vector3(x_plane, y,         z),
					Vector3(x_plane, y,         z + width),
					uv[0], uv[1], uv[2], uv[3]
				)

	# ------------------------------------------------------------
	# WEST (-X): plane at x, merge in Z (width) and Y (depth)
	# ------------------------------------------------------------
	for x in range(s):
		var mask := []
		mask.resize(s) # u = z
		for z in range(s):
			mask[z] = []
			mask[z].resize(s) # v = y
			for y in range(s):
				mask[z][y] = is_solid_world(chunk, world, chunk_coord, x, y, z) and not is_solid_world(chunk, world, chunk_coord, x - 1, y, z)

		for z in range(s):
			for y in range(s):
				if not mask[z][y]:
					continue

				var width := 1
				while z + width < s and mask[z + width][y]:
					width += 1

				var depth := 1
				while y + depth < s:
					var ok := true
					for i in range(width):
						if not mask[z + i][y + depth]:
							ok = false
							break
					if not ok:
						break
					depth += 1

				for dz in range(width):
					for dy in range(depth):
						mask[z + dz][y + dy] = false

				var uv : Array[Vector2] = uv_face[Face.WEST]
				var x_plane := x
				# Matches your original west winding:
				# (x,y+1,z) (x,y+1,z+1) (x,y,z+1) (x,y,z)
				out.add_quad(
					Vector3(x_plane, y + depth, z),
					Vector3(x_plane, y + depth, z + width),
					Vector3(x_plane, y,         z + width),
					Vector3(x_plane, y,         z),
					uv[0], uv[1], uv[2], uv[3]
				)

	# ------------------------------------------------------------
	# SOUTH (+Z): plane at z+1, merge in X (width) and Y (depth)
	# ------------------------------------------------------------
	for z in range(s):
		var mask := []
		mask.resize(s) # u = x
		for x in range(s):
			mask[x] = []
			mask[x].resize(s) # v = y
			for y in range(s):
				mask[x][y] = is_solid_world(chunk, world, chunk_coord, x, y, z) and not is_solid_world(chunk, world, chunk_coord, x, y, z + 1)

		for x in range(s):
			for y in range(s):
				if not mask[x][y]:
					continue

				var width := 1
				while x + width < s and mask[x + width][y]:
					width += 1

				var depth := 1
				while y + depth < s:
					var ok := true
					for i in range(width):
						if not mask[x + i][y + depth]:
							ok = false
							break
					if not ok:
						break
					depth += 1

				for dx in range(width):
					for dy in range(depth):
						mask[x + dx][y + dy] = false

				var uv : Array[Vector2] = uv_face[Face.SOUTH]
				var z_plane := z + 1
				# Matches your original south winding:
				# (x,y+1,z+1) (x+1,y+1,z+1) (x+1,y,z+1) (x,y,z+1)
				out.add_quad(
					Vector3(x,         y + depth, z_plane),
					Vector3(x + width, y + depth, z_plane),
					Vector3(x + width, y,         z_plane),
					Vector3(x,         y,         z_plane),
					uv[0], uv[1], uv[2], uv[3]
				)

	# ------------------------------------------------------------
	# NORTH (-Z): plane at z, merge in X (width) and Y (depth)
	# ------------------------------------------------------------
	for z in range(s):
		var mask := []
		mask.resize(s) # u = x
		for x in range(s):
			mask[x] = []
			mask[x].resize(s) # v = y
			for y in range(s):
				mask[x][y] = is_solid_world(chunk, world, chunk_coord, x, y, z) and not is_solid_world(chunk, world, chunk_coord, x, y, z - 1)

		for x in range(s):
			for y in range(s):
				if not mask[x][y]:
					continue

				var width := 1
				while x + width < s and mask[x + width][y]:
					width += 1

				var depth := 1
				while y + depth < s:
					var ok := true
					for i in range(width):
						if not mask[x + i][y + depth]:
							ok = false
							break
					if not ok:
						break
					depth += 1

				for dx in range(width):
					for dy in range(depth):
						mask[x + dx][y + dy] = false

				var uv : Array[Vector2] = uv_face[Face.NORTH]
				var z_plane := z
				# Matches your original north winding:
				# (x+1,y+1,z) (x,y+1,z) (x,y,z) (x+1,y,z)
				out.add_quad(
					Vector3(x + width, y + depth, z_plane),
					Vector3(x,         y + depth, z_plane),
					Vector3(x,         y,         z_plane),
					Vector3(x + width, y,         z_plane),
					uv[0], uv[1], uv[2], uv[3]
				)
	return out
