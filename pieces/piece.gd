class_name Piece extends Spatial


func _ready():
	pass # Replace with function body.

func rotate_piece():
	self.rotate_z(PI/2.0)
	
func piece_to_array() -> Array:
	var piece_parts = []
	for child in get_children():
		var pos = child.global_translation
		var x = int(floor(pos.x))
		var y = int(floor(pos.y))
		piece_parts.append([x,20-y, child])
	return piece_parts

