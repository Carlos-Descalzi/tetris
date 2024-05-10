extends Spatial


const _PIECES = [
	preload("res://pieces/Piece1.tscn"),
	preload("res://pieces/Piece2.tscn"),
	preload("res://pieces/Piece3.tscn"),
	preload("res://pieces/Piece4.tscn"),
	preload("res://pieces/Piece5.tscn"),
	preload("res://pieces/Piece6.tscn"),
	preload("res://pieces/Piece7.tscn"),
]
const _SCORES = [100,200,350,500]

var _rnd
var _keypressed = false
var _current_piece
var _board
var _score
var _is_game_over


func _ready():
	_rnd = RandomNumberGenerator.new()
	_rnd.randomize()
	_start()

	
func _start():
	_clear()
	$gameover.visible = false
	$Timer.paused = false
	_new_piece()	


func _clear():
	_is_game_over = false
	_reset_score()
	_board = _make_board()
	if _current_piece:
		_current_piece.queue_free()
		_current_piece = null
	
	for c in $PieceHolder.get_children():
		c.queue_free()
	for c in $piece_launcher.get_children():
		c.queue_free()
		
func _make_board():
	var board = []
	for n in range(20):
		board.append(_make_row())
	return board


func _make_row():
	var row = []
	for n in range(10):
		row.append(null)
	return row


func _new_piece():
	var index = _rnd.randi_range(0,len(_PIECES)-1)
	_current_piece = _PIECES[index].instance()
	
	var pos = $piece_launcher.global_translation
	add_child(_current_piece)
	_current_piece.global_translation = pos


func _on_Timer_timeout():
	if _current_piece and not _is_game_over:
		if not _try_move(_current_piece, Vector3(0,-1,0)):
			_stack(_current_piece)
			_handle_full_rows()
			_new_piece()
			if not _try_move(_current_piece, Vector3.ZERO):
				_game_over()


func _process(delta):
	if not _is_game_over:
		if Input.is_action_just_pressed("ui_left"):
			_try_move(_current_piece,Vector3(-1,0,0))
		elif Input.is_action_just_pressed("ui_right"):
			_try_move(_current_piece,Vector3(1,0,0))
		elif Input.is_action_pressed("ui_down"):
			_try_move(_current_piece,Vector3(0,-1,0))
		elif Input.is_action_just_pressed("ui_rotate"):
			_try_rotate(_current_piece)
	else:
		if Input.is_action_just_pressed("ui_rotate"):
			_start()

func _try_move(piece:Piece, vector:Vector3)->bool:
	var current_pos = piece.translation
	piece.translation += vector
	if _test_transform(piece):
		piece.translation = current_pos
		return false

	return true

	
func _try_rotate(piece:Piece)->bool:
	var current_rotation = piece.rotation
	piece.rotate_piece()
	if _test_transform(piece):
		piece.rotation = current_rotation
		return false
		
	return true


func _test_transform(piece: Piece)->bool:
	var piece_array = piece.piece_to_array()
	return _piece_out_of_bounds(piece_array) or _piece_collides(piece_array)
	

func _handle_full_rows():
	var full_rows = _get_full_rows()
	for row in full_rows:
		_kill_row(row)
	
	if len(full_rows):
		_inc_score(_SCORES[len(full_rows)-1])


func _get_full_rows()->Array:
	var rows = []
	for n in range(20):
		if _row_full(_board[n]):
			rows.append(n)
	return rows


func _row_full(row:Array)->bool:
	for cell in row:
		if not cell:
			return false
	return true


func _piece_out_of_bounds(piece_array:Array) -> bool:
	for part in piece_array:
		var x = part[0]
		var y = part[1]
		if x < 0 or x > 9 or y > 19:
			return true
	return false


func _piece_collides(piece_array:Array)->bool:
	for piece in piece_array:
		if _board[piece[1]][piece[0]]:
			return true
	return false


func _kill_row(row_index:int):
	var row = _board.pop_at(row_index)
	for item in row:
		if item:
			item.queue_free()

	for prev_row in range(0,row_index):
		for cell in _board[prev_row]:
			if cell:
				cell.global_translation.y-=1

	_board.insert(0,_make_row())


func _stack(piece:Piece):
	var piece_grid = piece.piece_to_array()

	for piece_item in piece_grid:
		var x = piece_item[0]
		var y = piece_item[1]
		var mesh = piece_item[2]
		
		_board[y][x] = mesh

		var tx = mesh.global_transform
		piece.remove_child(mesh)
		$PieceHolder.add_child(mesh)
		mesh.global_transform = tx

	piece.queue_free()


func _inc_score(score:int):
	_score += score
	$Control/Score.text = str(_score)


func _reset_score():
	_score = 0
	$Control/Score.text = str(_score)
	

func _game_over():
	$Timer.paused = true
	$gameover.visible = true
	_is_game_over = true
