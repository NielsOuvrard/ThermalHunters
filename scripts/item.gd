extends Node2D

@onready var item_sprite: Sprite2D = $ItemSprite


enum Type {
	PISTOL,
	RIFLE,
	SHOTGUN,
	KNIFE
}

@export var type_item := Type.RIFLE

var weapons = [
	{
		"name": "pistol",
		"scale": Vector2(0.7, 0.7),
		"texture": "res://assets/items/weapons/ColtPixel.png"
	},
	{
		"name": "rifle",
		"scale": Vector2(1, 1),
		"texture": "res://assets/items/weapons/Ak47Pixel.png"
	},
	{
		"name": "shotgun",
		"scale": Vector2(1, 1),
		"texture": "res://assets/items/weapons/Shotgun.png"
	},
	{
		"name": "knife",
		"scale": Vector2(0.5, 0.5),
		"texture": "res://assets/items/weapons/KnifePixel.png"
	}
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_sprite.texture = load(weapons[type_item].texture)
	item_sprite.scale = weapons[type_item].scale

func _on_area_2d_body_entered(body: Node2D) -> void:
	body.unlock_weapon(weapons[type_item].name)
	queue_free()
