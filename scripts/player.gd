extends CharacterBody2D

@onready var animated_body = $Body
@onready var animated_feet = $Feet
@onready var shoot_cooldown = $ShootCooldown
@onready var reload_cooldown = $ReloadCooldown
@onready var animation_player = $AnimationPlayer
@onready var pistol_reload = $pistol_reload
@onready var raycast = $RayCast2D

@export var SPEED = 300.0
const MAX_BULLETS = 6
const BLOOD = preload("res://scenes/blood.tscn")


enum State {
	IDLE,
	WALKING,
	RUNNING,
	SHOOTING,
	RELOAD,
	PUNCH
}

enum Hold {
	FLASHLIGHT,
	PISTOL,
	RIFLE,
	SHOTGUN
}

class Player:
	var state := State.IDLE
	var hold := Hold.PISTOL

	var can_shoot := true
	var is_reloading := false
	var is_punching := false

	var bullets := MAX_BULLETS

	var animated_body
	var animated_feet
	var shoot_cooldown
	var reload_cooldown
	var animation_player
	var pistol_reload
	var raycast
	var parent_node

	var hold_to_animation = {
		Hold.FLASHLIGHT: "light",
		Hold.PISTOL: "pistol",
		Hold.RIFLE: "rifle",
		Hold.SHOTGUN: "shotgun"
	}
	var state_to_animation = {
		State.IDLE: "idle",
		State.WALKING: "move",
		State.RUNNING: "run",
		State.SHOOTING: "shoot",
		State.RELOAD: "reload",
		State.PUNCH: "punch"
	}

	func _init(_animated_body, _animated_feet, _shoot_cooldown, _reload_cooldown, _animation_player, _pistol_reload, _raycast, _parent_node):
		self.animated_body = _animated_body
		self.animated_feet = _animated_feet
		self.shoot_cooldown = _shoot_cooldown
		self.reload_cooldown = _reload_cooldown
		self.animation_player = _animation_player
		self.pistol_reload = _pistol_reload
		self.raycast = _raycast
		self.parent_node = _parent_node
		print("Player created")
		print(animated_body) # <null>
		print(animated_feet) # <null>
		print(shoot_cooldown) # <null>
		print(reload_cooldown) # <null>
		print(animation_player) # <null>
		print(pistol_reload) # <null>
		print(raycast) # <null>
		print(parent_node) # <CharacterBody2D#83399541991>

	func update_animation():
		animated_body.play(hold_to_animation[hold] + "_" + state_to_animation[state])


	func shoot():
		can_shoot = false
		if bullets <= 0:
			reload()
			return
		state = State.SHOOTING
		shoot_cooldown.start()
		update_animation()
		animation_player.stop()
		animation_player.play("shoot") # sound y flash
		bullets -= 1

		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("enemies"):
				var blood = BLOOD.instantiate()
				parent_node.get_parent().add_child(blood)
				blood.position = raycast.get_collision_point()
				collider.queue_free()

	func reload():
		state = State.RELOAD
		reload_cooldown.start()
		is_reloading = true
		pistol_reload.play()
		bullets = MAX_BULLETS
		update_animation()

	func melee_attack():
		state = State.PUNCH
		reload_cooldown.start()
		is_punching = true
		update_animation()

var frame := 0 # for debug
var player

func _ready():
	player = Player.new(animated_body, animated_feet, shoot_cooldown, reload_cooldown, animation_player, pistol_reload, raycast, self)


func rotation_player():
	## * IF WE USE THE KEYBOARD TO LOOK THE PLAYER
	#var look_direction = Vector2.ZERO
	#if Input.is_action_pressed('move_right'):
		#look_direction.x += 1
	#if Input.is_action_pressed('move_left'):
		#look_direction.x -= 1
	#if Input.is_action_pressed('move_down'):
		#look_direction.y += 1
	#if Input.is_action_pressed('move_up'):
		#look_direction.y -= 1
		#
	#if look_direction != Vector2.ZERO:
		#rotation = look_direction.angle()

	var window_size = get_viewport().get_visible_rect().size
	var mouse_position = get_viewport().get_mouse_position() - window_size / 2
	
	## * IF THE CAMERA IS FIXED
	# var vector_look = Vector2(mouse_position.x - position.x, mouse_position.y - position.y)
	## * IF THE CAMERA FOLLOWS THE PLAYER
	var vector_look = mouse_position
	
	return vector_look.angle()  - 0.025 # 0.5 is the offset to make the player look at the mouse
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var direction_input = Vector2.ZERO

	if Input.is_action_pressed('look_right'):
		direction_input.x += 1
	if Input.is_action_pressed('look_left'):
		direction_input.x -= 1
	if Input.is_action_pressed('look_down'):
		direction_input.y += 1
	if Input.is_action_pressed('look_up'):
		direction_input.y -= 1
		
	rotation = rotation_player()

	var direction = direction_input
	# direction.x *= 0.7 # Reduce diagonal speed
	direction = direction.rotated(rotation + (PI / 2))
	if direction != Vector2.ZERO:
		velocity = delta * direction * SPEED
	else:
		velocity = Vector2.ZERO
		
	frame += delta
	if frame > 0.1:
		frame = 0
		#print(velocity.length())
	
	if Input.is_action_pressed('shoot') and player.can_shoot:
		player.shoot()
	
	if Input.is_action_pressed('reload') and not player.is_reloading:
		player.reload()
	
	if Input.is_action_pressed('melee_attack') and not player.is_punching:
		player.melee_attack()
	

	if not animated_body.is_playing(): # if not state reload nor shoot
		if direction_input != Vector2.ZERO:
			player.state = State.WALKING
		else:
			player.state = State.IDLE
		player.update_animation()
	
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
	player.can_shoot = true


func _on_reload_cooldown_timeout():
	player.is_reloading = false
	player.can_shoot = true
	player.is_punching = false
