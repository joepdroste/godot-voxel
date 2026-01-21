class_name ChunkMesh

var vertices : PackedVector3Array
var indices  : PackedInt32Array
var uvs      : PackedVector2Array

var _face_count := 0

func _init() -> void:
	vertices = PackedVector3Array()
	indices = PackedInt32Array()
	uvs = PackedVector2Array()

func clear():
	vertices.clear()
	indices.clear()
	uvs.clear()
	_face_count = 0

func add_quad(v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3,
			  uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2):
	
	vertices.append(v0)
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)

	indices.append(_face_count * 4 + 0)
	indices.append(_face_count * 4 + 1)
	indices.append(_face_count * 4 + 2)
	indices.append(_face_count * 4 + 0)
	indices.append(_face_count * 4 + 2)
	indices.append(_face_count * 4 + 3)

	uvs.append(uv0)
	uvs.append(uv1)
	uvs.append(uv2)
	uvs.append(uv3)

	_face_count += 1
