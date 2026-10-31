extends "res://scripts/ui/gm_text.gd"

const GOLD := Color8(212, 175, 55)
const SECONDARY := Color8(190, 190, 190)


func _ready() -> void:
	GameState.enter_screen(&"creditos")


func body(at: Vector2, text: String, factor: float, color: Color = Color.WHITE,
		separation: float = 43.0) -> void:
	# GML keeps fa_top after drawing the award, until the final footer.
	gm_text(at, text, factor, color, HORIZONTAL_ALIGNMENT_LEFT, false, separation)


func _draw() -> void:
	gm_text(Vector2(32, 32), "CREDITOS", 0.5)
	gm_text(Vector2(608, 12), "PROYECTO GANADOR\nFERIA CIENTIFICA\nFE Y ALEGRIA 2018", 0.15625, GOLD, HORIZONTAL_ALIGNMENT_RIGHT, false, 80)
	body(Vector2(32, 96), "HISTORIA", 0.25, GOLD)
	body(Vector2(352, 96), "AGRADECIMIENTOS", 0.25, GOLD)
	body(Vector2(32, 292), "LICENCIA", 0.25, GOLD)
	body(Vector2(32, 126), "PONG REMAKE", 0.25)
	body(Vector2(32, 158), "CREADO EN 2018 PARA LA\nFERIA CIENTIFICA DEL\nLICEO TECNICO PROFESIONAL\nCARDENAL SANCHA\nFE Y ALEGRIA 2018\nCON LA AYUDA DE 4 AMIGOS", 0.1875, Color.WHITE, 96)
	body(Vector2(32, 324), "ESTE JUEGO DEBE OBTENERSE\nPOR GITHUB\nDISTRIBUIDO BAJO\nLICENCIA GPL V3", 0.1875, Color.WHITE, 96)
	body(Vector2(352, 132), "HAROLD AQUINO", 0.1875)
	body(Vector2(352, 174), "STEWAR MEDRANO", 0.1875)
	body(Vector2(352, 216), "JOSE MIGUEL PENA", 0.1875)
	body(Vector2(352, 234), "RODRIGUEZ", 0.1875)
	body(Vector2(352, 252), "(YOMI)", 0.1875, SECONDARY)
	body(Vector2(352, 290), "JOSE GABRIEL COLON", 0.1875)
	body(Vector2(352, 332), "HECTOR ACOSTA", 0.1875)
	body(Vector2(352, 350), "(HEKTORPROFE)\nCANAL DE YOUTUBE EXTINTO", 0.1875, SECONDARY, 96)
	gm_text(Vector2(320, 432), "ESC PARA VOLVER A LA PORTADA", 0.1875, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
