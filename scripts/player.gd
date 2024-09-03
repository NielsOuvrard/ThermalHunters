extends CharacterBody2D

@export var speed = 200  # Speed of the player
@onready var animated_body = $Body
@onready var animated_feet = $Feet
@onready var shoot_cooldown = $ShootCooldown
@onready var reload_cooldown = $ReloadCooldown
@onready var animation_player = $AnimationPlayer
@onready var pistol_reload = $pistol_reload

const SPEED = 30000.0
const MAX_BULLETS = 6

var can_shoot = true
var is_reloading = false

var bullets = MAX_BULLETS

#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func shoot():
	can_shoot = false
	if bullets <= 0:
		reload()
		return
	shoot_cooldown.start()
	animated_body.play("shoot")
	animation_player.stop()
	animation_player.play("shoot")
	bullets -= 1

func reload():
	reload_cooldown.start()
	animated_body.play("reload")
	is_reloading = true
	pistol_reload.play()
	bullets = MAX_BULLETS

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var direction_input = Vector2.ZERO

	if Input.is_action_pressed('move_right'):
		direction_input.x += 1
	if Input.is_action_pressed('move_left'):
		direction_input.x -= 1
	if Input.is_action_pressed('move_down'):
		direction_input.y += 1
	if Input.is_action_pressed('move_up'):
		direction_input.y -= 1
		
		
	var look_direction = Vector2.ZERO

	if Input.is_action_pressed('look_right'):
		look_direction.x += 1
	if Input.is_action_pressed('look_left'):
		look_direction.x -= 1
	if Input.is_action_pressed('look_down'):
		look_direction.y += 1
	if Input.is_action_pressed('look_up'):
		look_direction.y -= 1
		
	if look_direction != Vector2.ZERO:
		rotation = look_direction.angle()

	var direction = direction_input
	direction.x *= 0.7 # Reduce diagonal speed
	direction = direction.rotated(rotation + (PI / 2))
	if direction != Vector2.ZERO:
		velocity = delta * direction * SPEED
	else:
		velocity = Vector2.ZERO
		
	if Input.is_action_pressed('shoot') and can_shoot:
		shoot()
	
	if Input.is_action_pressed('reload') and not is_reloading:
		reload()
	
	if not animated_body.is_playing():
		# TODO something for trarfe
		if direction_input != Vector2.ZERO:
			animated_body.play("move")
		else:
			animated_body.play("idle")
	
	if direction_input != Vector2.ZERO:
		if direction_input.x == 1:
			animated_feet.play("strafe_right")
		elif direction_input.x == -1:
			animated_feet.play("strafe_left")
		else:
			animated_feet.play("walk")
	else:
		animated_feet.play("idle")
	
	move_and_slide()


func _on_shoot_cooldown_timeout():
	can_shoot = true
	print("can shoot")


func _on_reload_cooldown_timeout():
	is_reloading = false
	can_shoot = true
	print("reload done")
