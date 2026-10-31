# Revisión final del porte

Fecha: 30 de octubre de 2026. Motor probado: Godot 4.7.2, Linux, renderizador
Compatibility/OpenGL sobre Intel HD Graphics 530. Las pruebas gráficas abrieron
una ventana real; la prueba de tiempo real mantuvo activo el reloj físico del motor.

## Resultados

| Prueba | Resultado |
| --- | --- |
| Importación/compilación de recursos y GDScript | Correcta |
| `test_menu.gd` | 51 comprobaciones, 0 fallos |
| `test_gameplay.gd` con ventana real | 359 comprobaciones, 0 fallos |
| `test_realtime.gd` | 6 comprobaciones, 0 fallos |
| Cierre por botón | PASS, 0.267 s en la ejecución comprobada |
| Cierre por Escape | PASS, 0.067 s |
| Cierre de ventana | PASS, 0.083 s |

Total: **419 comprobaciones aprobadas** contando las tres rutas de cierre.
El total no suma de nuevo las mismas pruebas repetidas sobre el paquete exportado.

La ejecución de estrés realizó **12 partidas completas, 78.149 pasos simulados
y 79 puntos naturales**. Se alternaron un jugador que seguía la pelota y otro
que permanecía en el límite superior. Ganaron el jugador y la CPU seis partidas
cada uno, cubriendo los modos a 3 y 10 puntos. No se inyectaron goles en estas
12 partidas. Las pruebas separadas de transición sí fuerzan posiciones de gol
para verificar todos los casos de ganador/modo y cada paso de la espera.

## Cobertura

- Los nueve sprites conservan sus dimensiones; las dos fuentes bitmap cargan;
  los siete WAV tienen duración válida y PCM de 16 bits sin compresión con pérdida.
- Botones: coordenadas, márgenes transparentes, escalado de Opciones, señales,
  cambio de escenas, modos y reinicio de marcador.
- Título: los tres botones del ratón, pausa modal, reanudación, extremos de
  oscilación y máscara alineada a ejes al rotar.
- Selector musical: orden de las tres pistas, bucles, persistencia, bordes
  inclusivos de su rectángulo y atenuación durante el juego.
- Saques: todas las combinaciones de posición/dirección, velocidad inicial y
  orientación correcta del eje vertical.
- Colisiones: paredes, centro y extremos de palas, velocidad máxima, ausencia
  de colisión al solo tocar bordes, solapamientos subpíxel y fallos verticales.
- Puntuación: ambos lados, ausencia de punto en la igualdad x=0/640, un solo
  punto por pelota, alarma de 90 pasos y estado conservado entre rondas.
- CPU: muestra retrasada incluso tras invertir la pelota, intervalo de
  observación, anticipación limitada por mitad, error persistente por tiro,
  aceleración, inercia, máximos de velocidad, límites y retorno sin pelota.
- Flujo: los cuatro casos de modo/ganador, música continua y cursor restaurado
  al terminar o pulsar Escape, incluso durante una espera de punto.
- Reloj real: 360 pasos a aproximadamente 60 Hz y espera de punto de 1.5 s
  con tolerancia de 80 ms para el muestreo de la prueba.
- Sonido: las voces de pared/pala/fallo reproducen sus recursos y un
  `AudioEffectCapture` comprueba salida no silenciosa del mezclador.
- Cierre: clic completo antes de salir, Escape y señal de cierre de ventana;
  terminación sin advertencias de recursos de audio pendientes.

Se revisaron las capturas de portada, opciones, créditos y tablero. Los textos,
fondos y sprites cargan correctamente. La comprobación de audio es técnica
(reproducción y muestras del mezclador), no una evaluación auditiva subjetiva.

## Correcciones realizadas durante la revisión

1. Conversión sin pérdida del atlas gris+alfa a RGBA para BMFont.
2. Tipado explícito de posiciones de eventos en GDScript y uso de coordenadas
   del evento para no depender de una lectura desfasada del puntero.
3. Ajuste de alineación superior en créditos conforme al estado de dibujo GML.
4. Máscara alineada a ejes del título rotado y bordes inclusivos del selector.
5. Comparación de límites de CPU antes de reducir la precisión a Vector2.
6. Eliminación de la pelota antes del siguiente paso para impedir doble punto.
7. Guardia de transición para evitar cambios de escena duplicados en un frame.
8. Liberación de voces de audio y breve drenaje del mezclador antes de salir.

## Distribución y alcance

El preset Linux produce `builds/PongRemake.pck` con los recursos y scripts
compilados. Los metadatos JSON de sprites se incluyen explícitamente; las
pruebas, herramientas y documentación quedan fuera del paquete.

Las pruebas de menú se ejecutan también con el PCK montado desde un directorio
ajeno al proyecto, usando el script de prueba como controlador externo. Esto
comprueba que las cuatro escenas pueden abrirse con los recursos empaquetados.

No hay un binario Linux independiente porque no están instaladas las plantillas
de exportación. El proyecto y el PCK se ejecutan con Godot instalado. No se han
validado exportaciones Windows, macOS, web ni dispositivos móviles.

No se afirma equivalencia binaria o cuadro a cuadro con el runner nativo de
GameMaker. Las adaptaciones y el orden de eventos elegido están explicados en
`PORTING.md`. El manifiesto `source_sha256.json` permite comprobar que los
111 archivos fuente inventariados permanecen intactos.
