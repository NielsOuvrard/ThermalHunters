extends CharacterBody2D

@onready var animated_body = $Body
@onready var animated_feet = $Feet
@onready var shoot_cooldown = $ShootCooldown
@onready var action_cooldown: Timer = $ActionCooldown
@onready var animation_player = $AnimationPlayer
@onready var pistol_reload = $pistol_reload
@onready var raycast = $RayCast2D

@export var SPEED = 300.0
const MAX_BULLETS = 6
const BLOOD = preload("res://scenes/blood.tscn")


enum State {
	IDLE,
	MOVE,
	SHOOTING,
	RELOAD,
	PUNCH
}

enum Hold {
	FLASHLIGHT,
	PISTOL,
	RIFLE,
	SHOTGUN,
	KNIFE
}

class Player:
	var state := State.IDLE
	var last_state := State.IDLE
	var hold := Hold.PISTOL
	var last_hold := Hold.PISTOL

	var bullets := MAX_BULLETS

	var animated_body
	var animated_feet
	var shoot_cooldown
	var action_cooldown
	var animation_player
	var pistol_reload
	var raycast
	var parent_node

	var state_to_animation = {
		State.IDLE: "idle",
		State.MOVE: "move",
		State.SHOOTING: "shoot", # not for flashlight nor knife
		State.RELOAD: "reload", # not for flashlight nor knife
		State.PUNCH: "punch"
	}

	var hold_to_animation = {
		Hold.FLASHLIGHT: "light",
		Hold.PISTOL: "pistol",
		Hold.RIFLE: "rifle",
		Hold.SHOTGUN: "shotgun",
		Hold.KNIFE: "knife"
	}

	func _init(_animated_body, _animated_feet, _shoot_cooldown, _action_cooldown, _animation_player, _pistol_reload, _raycast, _parent_node):
		self.animated_body = _animated_body
		self.animated_feet = _animated_feet
		self.shoot_cooldown = _shoot_cooldown
		self.action_cooldown = _action_cooldown
		self.animation_player = _animation_player
		self.pistol_reload = _pistol_reload
		self.raycast = _raycast
		self.parent_node = _parent_node

	func update_animation():
		if state != last_state or hold != last_hold:
			# animated_body.stop() # do we need this ?
			animated_body.play(hold_to_animation[hold] + "_" + state_to_animation[state])
			print(hold_to_animation[hold] + "_" + state_to_animation[state])
			last_state = state
			last_hold = hold

	func shoot():
		if bullets <= 0:
			reload()
			return
		state = State.SHOOTING
		shoot_cooldown.start()
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
		action_cooldown.start()
		pistol_reload.play()
		bullets = MAX_BULLETS

	func melee_attack():
		state = State.PUNCH
		action_cooldown.start()

	func change_weapon():
		action_cooldown.start()
		# for now
		if hold == Hold.FLASHLIGHT:
			hold = Hold.PISTOL
			print("change to pistol")
		else:
			hold = Hold.FLASHLIGHT
			print("change to flashlight")

var player

func _ready():
	player = Player.new(animated_body, animated_feet, shoot_cooldown, action_cooldown, animation_player, pistol_reload, raycast, self)

# do a boolean varaible "last_action_controller" to know if the last action was with the controller or mouse
func rotation_player():
	## * IF WE USE THE KEYBOARD TO LOOK THE PLAYER
	var direction_input = Vector2.ZERO

	if Input.is_action_pressed('look_right'):
		direction_input.x += Input.get_action_strength('look_right')
	if Input.is_action_pressed('look_left'):
		direction_input.x -= Input.get_action_strength('look_left')
	if Input.is_action_pressed('look_down'):
		direction_input.y += Input.get_action_strength('look_down')
	if Input.is_action_pressed('look_up'):
		direction_input.y -= Input.get_action_strength('look_up')

	if direction_input != Vector2.ZERO:
		return direction_input

	var window_size = get_viewport().get_visible_rect().size
	var mouse_position = get_viewport().get_mouse_position() - window_size / 2
	return mouse_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var direction_input = Vector2.ZERO

	if Input.is_action_pressed('fmove_right'):
		direction_input.x += Input.get_action_strength('fmove_right')
	if Input.is_action_pressed('fmove_left'):
		direction_input.x -= Input.get_action_strength('fmove_left')
	if Input.is_action_pressed('fmove_down'):
		direction_input.y += Input.get_action_strength('fmove_down')
	if Input.is_action_pressed('fmove_up'):
		direction_input.y -= Input.get_action_strength('fmove_up')
		
	var rotation_vector = rotation_player()
	if rotation_vector != Vector2.ZERO:
		rotation = rotation_vector.angle()

	var direction = direction_input
	if direction != Vector2.ZERO:
		velocity = delta * direction * SPEED
	else:
		velocity = Vector2.ZERO
		
	

	if action_cooldown.is_stopped():
		if Input.is_action_pressed('shoot') and shoot_cooldown.is_stopped():
			player.shoot()

		if Input.is_action_pressed('reload'):
			player.reload()
		
		if Input.is_action_pressed('melee_attack'):
			player.melee_attack()
		
		if Input.is_action_pressed('change_weapon'):
			player.change_weapon()

	if action_cooldown.is_stopped() and shoot_cooldown.is_stopped():
		if direction_input != Vector2.ZERO:
			player.state = State.MOVE
		else:
			player.state = State.IDLE
	
	if direction_input != Vector2.ZERO:
		if direction_input.x == 1:
			animated_feet.play("strafe_right")
		elif direction_input.x == -1:
			animated_feet.play("strafe_left")
		else:
			animated_feet.play("walk")
	else:
		animated_feet.play("idle")

	player.update_animation()
	move_and_slide()
