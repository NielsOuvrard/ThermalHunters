extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready():
	# Add the player to the "player" group.
	add_to_group("enemies")

func _physics_process(_delta):
	pass
	# Add the gravity.
	#move_and_slide()
