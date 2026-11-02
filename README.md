# Pong Remake Remastered — Godot

Versión de Pong Remake portada de GameMaker a Godot 4, con partidas contra la CPU, selección de partidas a 3 o 10 puntos y tres pistas musicales. El proyecto puede abrirse y ejecutarse sin tener instalado GameMaker ni disponer del proyecto original.

Desarrollado y probado con Godot 4.7.2, utilizando el renderizador Compatibility y una ventana de 640 × 480.

## Estructura del proyecto

```text
project.godot       Configuración principal: importar este archivo en Godot.
export_presets.cfg  Presets de exportación para Linux y Windows.
scenes/             Pantallas y componentes reutilizables.
scripts/            Código GDScript organizado por responsabilidad.
assets/             Sprites, audio, fuente bitmap e iconos.
tests/              Pruebas automatizadas del juego.
tools/              Herramientas de importación de recursos GameMaker.
docs/               Documentación del port y validación.
builds/             Ejecutables exportados; excluidos de Git.
```

Los archivos `.tscn` describen escenas y nodos; los `.gd` contienen su comportamiento. Los archivos `.uid` y los ajustes `.import` acompañan a los recursos para mantener sus referencias y configuración. La caché generada en `.godot/` no se versiona.

### Escenas (`scenes/`)

| Escena | Función |
| --- | --- |
| `portada.tscn` | Menú principal y selección de partida; escena inicial. |
| `tablero.tscn` | Campo de juego contra la CPU. |
| `opciones.tscn` | Opciones y selección musical. |
| `creditos.tscn` | Créditos. |
| `components/background.tscn` | Fondo reutilizable. |
| `components/ball.tscn` | Pelota. |
| `components/paddle.tscn` | Paleta. |
| `components/sprite_button.tscn` | Botón basado en un sprite. |

### Estado y audio (`scripts/autoload/`)

Estos scripts se registran como autoloads en `project.godot` y permanecen disponibles al cambiar de escena.

- `game_state.gd` (`GameState`): estado de sesión, navegación con Escape, transiciones y cierre del juego.
- `audio_manager.gd` (`AudioManager`): reproducción de efectos y música persistente. Todas las pistas bajan al 30 % durante una partida.

### Jugabilidad (`scripts/gameplay/`)

- `board.gd`: coordina las fases de simulación del tablero.
- `ball.gd`: movimiento de la pelota, colisiones, rebotes y puntos.
- `paddle.gd`: comportamiento de las paletas y control del jugador.
- `cpu.gd`: lógica del rival, con observación retrasada, anticipación e inercia.

La simulación se ejecuta a 60 pasos por segundo. Se utilizan colisiones personalizadas para conservar el comportamiento del original de GameMaker, en lugar de delegarlo en cuerpos físicos de Godot.

### Interfaz (`scripts/ui/`)

- `portada.gd`, `opciones.gd`, `creditos.gd`: lógica de las pantallas del menú.
- `sprite_button.gd`: interacción y presentación de botones.
- `title.gd`, `remastered.gd`: título animado y subtítulo «REMASTERED».
- `scoreboard.gd`: presentación del marcador.
- `gm_text.gd`: utilidades para dibujar texto con la fuente bitmap.

### Recursos y documentación

- `assets/sprites/`: imágenes y `metadata.json`, con orígenes y zonas de interacción del original.
- `assets/audio/`: efectos y pistas musicales.
- `assets/fonts/`: fuente bitmap `fnt_marcador` y su atlas.
- `docs/PORTING.md`: correspondencias y adaptaciones entre motores.
- `docs/VALIDATION.md`: informe de revisión del port.
- `docs/source_sha256.json`: hashes de los archivos de origen registrados durante la importación.

## Abrir y ejecutar

Importa `project.godot` en Godot y pulsa F5 para iniciar el juego. También puedes ejecutar estos comandos desde la raíz de este repositorio:

```bash
godot --editor --path .
godot --path .
```

## Controles

- Ratón: mueve verticalmente la paleta derecha.
- Clic izquierdo: interactúa con los menús.
- Escape: vuelve al menú; desde la portada, cierra el juego.
- Opciones: alterna entre las pistas OFICIAL, EPICA y ORIGINAL.
- Clic izquierdo, derecho o central sobre el título: muestra los mensajes del original.

## Pruebas

Desde la raíz del repositorio:

```bash
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/test_menu.gd
godot --headless --path . --script res://tests/test_gameplay.gd
godot --path . --script res://tests/test_realtime.gd
godot --headless --path . --script res://tests/test_exit.gd
godot --headless --path . --script res://tests/test_exit.gd -- escape
godot --headless --path . --script res://tests/test_exit.gd -- window
```

Las pruebas de cierre se ejecutan por separado porque terminan el proceso. Las pruebas gráficas requieren una sesión de escritorio; sus capturas utilizan rutas locales descritas en los propios scripts.

## Descargar y exportar

Los builds disponibles se publican en [Releases](https://github.com/CJ-Montero/Pong-Remake-Remastered-Godot/releases), fuera del historial Git:

- `PongRemake.x86_64`: ejecutable para Linux x86_64.
- `PongRemake.exe`: ejecutable para Windows x86_64.

En Linux:

```bash
chmod +x PongRemake.x86_64
./PongRemake.x86_64
```

Para regenerarlos, instala las plantillas de exportación de tu versión de Godot, crea la carpeta `builds/` si no existe y ejecuta:

```bash
godot --headless --path . --export-release "Linux" builds/PongRemake.x86_64
godot --headless --path . --export-release "Windows Desktop" builds/PongRemake.exe
```

Ambos presets tienen activada la integración del PCK en el ejecutable. La exportación para Windows debe verificarse en Windows; publicarla no implica que se haya probado en ese sistema.

## Importador de GameMaker

`tools/import_gamemaker_assets.py` copia recursos y genera metadatos y fuentes BMFont. Requiere Python 3 y FFmpeg.

Es una herramienta opcional: no es necesaria para jugar ni para exportar. Actualmente busca `Pong Remake.yyp` en la carpeta superior a este repositorio (`SOURCE = DEST.parent`). Con los proyectos separados en carpetas hermanas, esa ruta debe adaptarse antes de volver a importar. No lo ejecutes sin revisar primero el origen y los recursos que regenerará.

## Archivos generados

`.gitignore` excluye `.godot/`, `builds/` y paquetes exportados. El código, las escenas, los recursos originales y sus ajustes de importación sí se versionan.

## Proyecto original

La versión de GameMaker está disponible en [Pong Remake Remastered — GameMaker](https://github.com/CJ-Montero/Pong-Remake-Remasted-GameMaker).
