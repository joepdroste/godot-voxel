extends CharacterBody3D
class_name Player

const SPEED = 10.0
const FLY_SPEED = 15.0
const MOUSE_SENSITIVITY = 0.003

@onready var camera := $Camera3D
@onready var world: World = get_parent()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Trigger initial chunk generation
	if world:
		world.update_chunks_around_player(global_position)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Get input direction (WASD)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Horizontal movement
	if direction:
		velocity.x = direction.x * FLY_SPEED
		velocity.z = direction.z * FLY_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, FLY_SPEED)
		velocity.z = move_toward(velocity.z, 0, FLY_SPEED)
	
	# Vertical movement (Space to go up, Shift to go down)
	velocity.y = 0
	if Input.is_action_pressed("ui_accept"):  # Space
		velocity.y = FLY_SPEED
	elif Input.is_action_pressed("ui_select"):  # Shift
		velocity.y = -FLY_SPEED

	move_and_slide()
	
	# Update chunks based on player position
	if world:
		world.update_chunks_around_player(global_position)
