# Correspondencia y decisiones del porte

## Fuente

38 recursos registrados: 14 objetos, 4 rooms, 9 sprites, 7 sonidos,
2 fuentes y 2 notas. 29 archivos GML activos, sin scripts independientes,
shaders, tilesets, secuencias ni archivos incluidos. Room inicial: `rm_portada`.
Resolución: 640 × 480; `option_game_speed = 60`.

`source_sha256.json` registra el contenido fuente leído durante la importación.
Los archivos `.old`, `.gms1` y `.gamemaker-mcp/backups/` son históricos;
los recursos activos son los que referencia el `.yyp`.

## Correspondencia completa

| GameMaker | Godot |
| --- | --- |
| `obj_controlador` persistente | `GameState` + `AudioManager`, autoloads |
| `rm_portada` | `scenes/portada.tscn` |
| `rm_opciones` | `scenes/opciones.tscn` |
| `rm_creditos` | `scenes/creditos.tscn` |
| `rm_tablero` | `scenes/tablero.tscn` |
| `obj_bola` | `ball.tscn` + `gameplay/ball.gd` |
| `obj_jugador` | `paddle.tscn` + `gameplay/paddle.gd` |
| `obj_cpu` | instancia de `paddle.tscn` + `gameplay/cpu.gd` |
| `obj_marcador` persistente | puntuación de `GameState` + `ui/scoreboard.gd` |
| `obj_btn` | `sprite_button.tscn` + señal `pressed` |
| `obj_btn_3_puntos`, `obj_btn_10_puntos` | botones que llaman a `GameState.request_match` |
| `obj_btn_salir` | botón y alarma de pasos en `ui/portada.gd` |
| `obj_creditos`, `obj_opciones` | botones de navegación en `portada.tscn` |
| `obj_btn_musica` | `ui/opciones.gd` y `AudioManager.cycle_music` |
| `obj_texto_creditos` | `ui/creditos.gd` |
| `obj_titulo` | `Sprite2D`, `title.gd`, `AcceptDialog` |
| `draw_text_transformed` | fuente BMFont + `gm_text.gd` |
| fondo `bg_tablero` | `background.tscn`, Sprite2D 640 × 480 |

Los controles son Node2D para que sus coordenadas, escalas, orígenes y cajas
de clic coincidan con los datos de GameMaker; las señales sustituyen las
acciones heredadas. No se amplían los clics a toda la superficie transparente
de cada PNG. El escalado 1.16 de Opciones se conserva.

La animación del título usa pasos fijos y los dos `if` independientes del GML.
Esto conserva la peculiaridad del extremo negativo: el paso que alcanza -10°
también ejecuta la rama ascendente y termina en -9.5°. Godot invierte el signo
del ángulo para mantener el sentido de rotación de GameMaker.

La salida por botón espera 12 pasos, equivalentes a
`ceil(0.169161 * 60) + 1`, sin reiniciar la espera con clics adicionales.

El audio vive fuera de las escenas: un reproductor de música y voces separadas
para los efectos. Las pistas usan bucle de muestras, sin reinicio por cambio
de menú. Los WAV están importados sin compresión con pérdida. Se conserva la
regla de ganancia 0.3 para toda la música durante una partida y 1.0 en los
menús. El comportamiento de Godot y el proyecto original de GameMaker se
actualizaron para aplicar esta atenuación de forma idéntica.

Las fuentes reutilizan atlas, desplazamientos, avances y altura de línea.
No requiere instalar 8BIT WONDER. `fnt_creditos` quedó sin referencias activas
y su atlas gris+alfa fue descartado durante este refactor.

## Adaptaciones identificadas

- Cuatro audios son WAV sin extensión: las copias reciben `.wav`.
- El atlas `fnt_creditos.png` usa gris+alfa, formato que el importador BMFont
  de Godot rechaza. Se expanden sus canales a RGBA sin cambiar la imagen visible.
- El atlas activo no tiene glifo `>`, aunque Opciones lo solicita. Se dibuja
  una pequeña flecha con líneas para evitar el carácter de sustitución de Godot.
  Es una adaptación visual explícita, no una reproducción pixel a pixel de
  cómo cada motor trata caracteres ausentes.
- `show_message()` se traduce a `AcceptDialog` con el árbol pausado y audio
  continuo. Mantiene textos y bloqueo modal; cambia el aspecto del diálogo.
- La contención del cursor de los menús secundarios usa el modo confinado
  del motor, en lugar de reposicionar el puntero en cada Step. En el tablero
  se usa `MOUSE_MODE_CONFINED_HIDDEN` y se centra el cursor en cada ronda.
- El cierre libera los reproductores y deja 50 ms al hilo de audio antes de
  terminar el proceso. Esto elimina referencias de audio pendientes al cerrar
  Godot. La espera original de 12 pasos del botón Salir se mantiene antes de
  esta limpieza; Escape y el cierre de ventana no esperan el sonido de clic.
- Los créditos visibles dicen GPL V3 y la nota antigua contiene MIT.
  Se conserva el texto de la pantalla; la discrepancia de las fuentes se
  registra aquí sin decidir una nueva licencia para los recursos.

## Simulación y colisiones

`board.gd` dirige la simulación a 60 pasos/s y el render está limitado a 60 FPS.
Las alarmas se actualizan antes de Step. Después se ejecutan pelota, jugador,
CPU y finalmente el movimiento automático de la pelota. Esta última fase es
importante: `instance_place(x+hspeed,y+vspeed,...)` consulta la posición siguiente,
pero el punto se detecta con la posición actual. Por tanto, cruzar x=0 o x=640
durante el movimiento se puntúa en el siguiente paso, como en el GML.

Se usa la dirección de GameMaker: `(cos(ángulo), -sin(ángulo))`. La velocidad
inicial es 5 px/paso, aumenta 0.5 con cada impacto en pala y se limita a 25.
Cada saque elige y=140/240/340 y dirección=45/135/225/315.

Las máscaras se toman de los `.yy` activos: pelota 19×20, desplazamiento
(-9,-10); pala 16×59, desplazamiento (-8,-29). El modo de compatibilidad de
colisiones está desactivado. Se consideran bordes derecho/inferior exclusivos
y se rechazan solapamientos subpíxel sin centro de píxel compartido.
La CPU utiliza el borde derecho de la máscara moderna para anticipar contacto.

Se eligió Node2D con colisión explícita en vez de `CharacterBody2D` o cuerpos
rígidos: la respuesta física automática, la separación de cuerpos o el barrido
continuo cambiarían las fórmulas de rebote y el momento de detección del original.
No se introduce una velocidad mínima vertical, protección direccional extra
ni rebote especular en las palas que el GML no contiene.

La comprobación de paredes conserva los límites 82/440 y la condición estricta
`<`/`>`: puede verse un paso de sobrepaso antes de corregirse. Las palas conservan
límites distintos: jugador 106–418 y CPU 115–410.

## CPU y rondas

La CPU decide con la muestra anterior y después registra la actual. Reacción
de 0.06 s (una observación cada cuatro pasos a 60 Hz), anticipación recta máxima
de 0.12 s solo en su mitad, error constante por tiro de ±8, zona muerta de 3,
aceleración de 1.5 px/paso² y velocidades máximas 7 (tiro entrante) / 4 (retorno).
No calcula futuros rebotes ni el punto final de llegada. Su posición de descanso
es y=261, el centro de los límites de la pelota.

Los puntos viven en el autoload y las rondas recrean la pelota y reinician las
palas y toda la memoria de la CPU. El estado de música permanece. Los 90 pasos
de espera empiezan en el paso posterior al punto; durante ellos siguen moviéndose
las palas. El punto ganador también espera 90 pasos antes de volver a portada.
La siguiente partida reinicia el marcador a cero. Escape elimina la escena y
su contador, por lo que no queda una alarma que cambie de pantalla después.

## Límites de equivalencia y referencias

- Los números aleatorios mantienen opciones y rangos, pero Godot y GameMaker
  no producen la misma secuencia. Se usa un generador de sesión aleatorizado
  al entrar al tablero; las pruebas pueden fijar su semilla.
- GameMaker no garantiza el orden entre instancias dentro de un mismo Step.
  Aquí se fija explícitamente el orden de creación que contiene `rm_tablero`:
  pelota → jugador → CPU. Así el porte es reproducible; no se puede prometer
  igualdad paso a paso con todos los runtimes/plataformas de GameMaker.
- GDScript usa dobles para escalares, pero Vector2 suele almacenar float32.
  Puede haber diferencias numéricas minúsculas frente a GML. Se corrigió un
  caso importante: comparar la posición redondeada con un valor doble hacía
  que la CPU cancelase su inercia. Ahora se detecta el límite antes de asignar
  la posición al nodo.
- Con retrasos de render, Godot puede ejecutar varios pasos físicos para
  mantener el tiempo de simulación. El comportamiento con sobrecarga extrema
  no es idéntico al Step/delta_time variable del runner de GameMaker.

Referencias usadas para contrastar la semántica, además del GML y los `.yy`:

- [Orden oficial de eventos](https://manual.gamemaker.io/monthly/en/The_Asset_Editors/Object_Properties/Event_Order.htm).
- [Runner HTML5 público: bounding boxes y colisiones](https://github.com/YoYoGames/GameMaker-HTML5/blob/develop/scripts/yyInstance.js),
  métodos `Compute_BoundingBox`, `Collision_Instance` y `Collision_Point`.

No se ha realizado una comparación cuadro a cuadro ejecutando el runner nativo
de GameMaker. La fidelidad se ha contrastado con el código fuente, estas
referencias y las pruebas descritas en `VALIDATION.md`.
