extends CharacterBody2D

@onready var animated_body: AnimatedSprite2D = $Body
@onready var animated_feet: AnimatedSprite2D = $Feet
@onready var shoot_cooldown: Timer = $ShootCooldown
@onready var action_cooldown: Timer = $ActionCooldown
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pistol_reload: AudioStreamPlayer2D = $pistol_reload
@onready var raycast: RayCast2D = $RayCast2D

@export var SPEED = 300.0
const MAX_BULLETS = 6
const BLOOD = preload("res://scenes/blood.tscn")

var weapons = [
	{
		"name": "light",
		"index": 0,
		"range": 10,
		"damage": 4,
		"cooldown_shot": 0.5,
		"cooldown_action": 0.93,
		"ammo_max": 0,
		"unlocked": true,
		# put here the light effect, instead of shooting
	},
	{
		"name": "pistol",
		"index": 1,
		"range": 300,
		"damage": 10,
		"cooldown_shot": 0.2, # in seconds
		"cooldown_action": 0.93,
		"ammo_max": 6,
		"unlocked": false,
		# put here the shooting effect
	},
	{
		"name": "rifle",
		"index": 2,
		"range": 200,
		"damage": 15,
		"cooldown_shot": 0.05,
		"cooldown_action": 0.93,
		"ammo_max": 30,
		"unlocked": false,
		# put here the shooting effect
	},
	{
		"name": "shotgun",
		"index": 3,
		"range": 150,
		"damage": 20,
		"cooldown_shot": 0.5,
		"cooldown_action": 0.93,
		"ammo_max": 2,
		"unlocked": false,
		# put here the shooting effect
	},
	{
		"name": "knife",
		"index": 4,
		"range": 50,
		"damage": 30,
		"cooldown_shot": 0,
		"cooldown_action": 0.93,
		"ammo_max": 0,
		"unlocked": false,
		# put here nothing
	}
]

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

func unlock_weapon(name: String) -> void:
	for weapon in weapons:
		if weapon.name == name:
			weapon.unlocked = true
			break


# ? switch to the new weapon when we unlock it
# ? reload the weapon when last bullet is shot

class Player:
	var state := State.IDLE
	var last_state := State.IDLE
	var hold := Hold.FLASHLIGHT
	var last_hold := Hold.FLASHLIGHT

	var bullets := MAX_BULLETS

	var animated_body
	var animated_feet
	var shoot_cooldown
	var action_cooldown
	var animation_player
	var pistol_reload
	var raycast
	var weapons
	var parent_node

	var state_to_animation = {
		State.IDLE: "idle",
		State.MOVE: "move",
		State.SHOOTING: "shoot", # not for flashlight nor knife
		State.RELOAD: "reload", # not for flashlight nor knife
		State.PUNCH: "punch"
	}

	# var hold_to_animation = {
	# 	Hold.FLASHLIGHT: "light",
	# 	Hold.PISTOL: "pistol",
	# 	Hold.RIFLE: "rifle",
	# 	Hold.SHOTGUN: "shotgun",
	# 	Hold.KNIFE: "knife"
	# }

	func _init(_animated_body, _animated_feet, _shoot_cooldown, _action_cooldown, _animation_player, _pistol_reload, _raycast, _weapons, _parent_node):
		self.animated_body = _animated_body
		self.animated_feet = _animated_feet
		self.shoot_cooldown = _shoot_cooldown
		self.action_cooldown = _action_cooldown
		self.animation_player = _animation_player
		self.pistol_reload = _pistol_reload
		self.raycast = _raycast
		self.weapons = _weapons
		self.parent_node = _parent_node

	func update_animation():
		if state != last_state or hold != last_hold:
			# animated_body.stop() # do we need this ?
			animated_body.play(weapons[hold].name + "_" + state_to_animation[state])
			print(weapons[hold].name + "_" + state_to_animation[state])
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
		print("bullets: ", bullets)

		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("enemies"):
				var blood = BLOOD.instantiate()
				parent_node.get_parent().add_child(blood)
				blood.position = raycast.get_collision_point()
				collider.queue_free()

	func reload():
		if bullets == weapons[hold].ammo_max:
			return
		state = State.RELOAD
		action_cooldown.start()
		pistol_reload.play()
		bullets = weapons[hold].ammo_max

	func melee_attack():
		state = State.PUNCH
		action_cooldown.start()

	func all_unlocked_weapons():
		var unlocked = []
		for weapon in weapons:
			if weapon.unlocked:
				unlocked.append(weapon)
		return unlocked

	func change_weapon():
		var unlocked = all_unlocked_weapons()
		if unlocked.size() == 1:
			return
		var index = unlocked.find(weapons[hold])

		action_cooldown.start()
		hold = unlocked[(index + 1) % unlocked.size()].index
		
		shoot_cooldown.wait_time = weapons[hold].cooldown_shot
		action_cooldown.wait_time = weapons[hold].cooldown_action

		# ! change later to the animation of the weapon
		bullets = weapons[hold].ammo_max


var player

func _ready():
	player = Player.new(animated_body, animated_feet, shoot_cooldown, action_cooldown, animation_player, pistol_reload, raycast, weapons, self)

# do a boolean varaible "last_action_controller" to know if the last action was with the controller or mouse
func rotation_player():
	var direction_input = Vector2.ZERO

	if Input.is_action_pressed('look_right'):
		direction_input.x += Input.get_action_strength('look_right')
	if Input.is_action_pressed('look_left'):
		direction_input.x -= Input.get_action_strength('look_left')
	if Input.is_action_pressed('look_down'):
		direction_input.y += Input.get_action_strength('look_down')
	if Input.is_action_pressed('look_up'):
		direction_input.y -= Input.get_action_strength('look_up')

	# * if we are using the controller
	if direction_input != Vector2.ZERO:
		return direction_input

	# * if we are using the mouse
	var window_size = get_viewport().get_visible_rect().size
	var mouse_position = get_viewport().get_mouse_position() - window_size / 2
	return mouse_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# * movement
	var direction_input = Vector2.ZERO

	if Input.is_action_pressed('fmove_right'):
		direction_input.x += Input.get_action_strength('fmove_right')
	if Input.is_action_pressed('fmove_left'):
		direction_input.x -= Input.get_action_strength('fmove_left')
	if Input.is_action_pressed('fmove_down'):
		direction_input.y += Input.get_action_strength('fmove_down')
	if Input.is_action_pressed('fmove_up'):
		direction_input.y -= Input.get_action_strength('fmove_up')

	var direction = direction_input
	if direction != Vector2.ZERO:
		velocity = delta * direction * SPEED
	else:
		velocity = Vector2.ZERO
		
	# * rotation
	var rotation_vector = rotation_player()
	if rotation_vector != Vector2.ZERO:
		rotation = rotation_vector.angle()
		
	# * actions
	if action_cooldown.is_stopped():
		if Input.is_action_pressed('shoot') and shoot_cooldown.is_stopped():
			player.shoot()

		if Input.is_action_pressed('reload'):
			player.reload()
		
		if Input.is_action_pressed('melee_attack'):
			player.melee_attack()
		
		if Input.is_action_pressed('change_weapon'):
			player.change_weapon()

	# * if we are not doing any action -> idle or move
	if action_cooldown.is_stopped() and shoot_cooldown.is_stopped():
		if direction_input != Vector2.ZERO:
			player.state = State.MOVE
		else:
			player.state = State.IDLE
	
	# * animations feet
	# ! should be according to the direction AND the rotation
	if direction != Vector2.ZERO:
		if direction.x >= 0.9:
			animated_feet.play("strafe_right")
		elif direction.x <= -0.9:
			animated_feet.play("strafe_left")
		else:
			animated_feet.play("walk")
	else:
		animated_feet.play("idle")

	player.update_animation()
	move_and_slide()
