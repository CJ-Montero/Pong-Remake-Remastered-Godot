# Pong Remake — porte a Godot 4.x

## Estado: porte completo y jugable

Proyecto creado a partir de `../Pong Remake.yyp`. Probado con Godot 4.7.2.

Implementado:

- Portada con posiciones, orígenes y zonas de clic de los sprites originales.
- Oscilación del título a 60 pasos/s y sus tres mensajes al pulsarlo.
- Opciones, créditos, navegación con Escape y transparencia de botones.
- Tres músicas en bucle, selección persistente y efectos de clic.
- Partidas a 3/10 puntos, marcador persistente y vuelta a portada al ganar.
- Pelota con saques aleatorios, rebotes según el impacto y aceleración hasta 25 px/paso.
- Pala del jugador controlada por ratón; CPU con reacción, observaciones retrasadas e inercia.
- Espera de 1,5 segundos entre puntos, reinicio de palas, CPU y saque.
- Cursor oculto y confinado durante la partida, restaurado al regresar al menú.
- Importación de los 9 sprites, 7 audios y 2 fuentes bitmap.

Las cuatro rooms están implementadas. Los detalles de equivalencia y las
adaptaciones entre motores están en `docs/PORTING.md`. El informe de revisión
está en `docs/VALIDATION.md`.

## Controles

- Ratón: mover verticalmente la pala derecha; clic izquierdo para los menús.
- Escape: volver a portada; desde portada, salir del juego.
- Opciones: alternar entre música OFICIAL, EPICA y ORIGINAL.
- Clic izquierdo/derecho/central sobre el título: mensajes originales.

## Abrir

Importa `project.godot` en Godot y pulsa F6 en una escena o F5 para la portada.
Desde la carpeta de GameMaker:

```sh
godot --editor --path godot
```

Para ejecutar directamente:

```sh
godot --path godot
```

## Estructura

- `scenes/`: portada, tablero, opciones, créditos y componentes reutilizables.
- `scripts/autoload/`: estado de sesión y audio persistente.
- `scripts/gameplay/`: fases de simulación, pelota, pala y CPU.
- `scripts/ui/`: señales de botones, título y dibujo de textos bitmap.
- `assets/`: copias de los recursos y fuentes en formato BMFont.
- `tools/import_gamemaker_assets.py`: importador reproducible, Python 3 + FFmpeg.
- `tests/`: menús, jugabilidad, partidas completas, reloj/audio real y salida.
- `docs/`: decisiones y hashes del código y recursos de origen.

El proyecto Godot puede abrirse y ejecutarse sin el proyecto GameMaker.
Solo el importador necesita los archivos originales en la carpeta superior.

## Verificación

```sh
godot --headless --editor --path godot --import
godot --headless --path godot --script res://tests/test_menu.gd
godot --headless --path godot --script res://tests/test_gameplay.gd
godot --path godot --script res://tests/test_realtime.gd
godot --headless --path godot --script res://tests/test_exit.gd
godot --headless --path godot --script res://tests/test_exit.gd -- escape
godot --headless --path godot --script res://tests/test_exit.gd -- window
```

Para revisar también el renderizado de los menús y la jugabilidad, ejecutar
sus pruebas sin `--headless`. Las pruebas gráficas guardan capturas en
`/tmp/opencode/pong-*.png` en esta máquina y terminan automáticamente.
Las pruebas de cierre se ejecutan en procesos separados porque cierran el juego.

## Paquete exportado

Se ha generado `builds/PongRemake.pck`, ejecutable mediante la misma versión
de Godot usada para exportarlo:

```sh
godot --main-pack "godot/builds/PongRemake.pck"
```

Para regenerarlo desde la carpeta superior:

```sh
godot --headless --path godot --export-pack Linux builds/PongRemake.pck
```

El preset incluye explícitamente `assets/sprites/metadata.json`, necesario para
las zonas de clic, y excluye pruebas, herramientas y documentación.
El paquete no depende de los archivos de GameMaker ni de la carpeta fuente Godot.

Para crear un ejecutable Linux independiente del editor, instala las plantillas
de exportación de tu versión de Godot y usa el preset Linux. En esta máquina
se validó el proyecto y el PCK; no hay plantillas instaladas para generar ese binario.
