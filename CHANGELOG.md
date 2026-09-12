# Changelog

## [1.0.2] - 2026-09-12

### Añadido
- **Metadatos en cada PDF**: Title = código, Subject = descripción, Author =
  `GeneradorEtiquetas <versión>` (comprobados con `pdfinfo` en la prueba del core).
- **Barra de progreso** en CLI (solo cuando stdout es una TTY; `tty-progressbar`
  opcional) y **`Gtk::ProgressBar`** en la GUI durante la generación, vía el nuevo
  callback `en_progreso:` de `Maquina#procesar` (también útil para otras UIs).
- Resumen del CLI: indica el **tiempo transcurrido** (`En 0.42 s`).

### Otro
- Se elimina la constante muerta `Dimensiones::TAMANO_ETIQUETA_NUM_PT`.

## [1.0.1] - 2026-09-12

### Añadido
- **Soporte CSV** en la lectura (`Libro`, CLI y GUI): los `.csv` se tratan igual que
  las hojas (`data/demo/codigos_demo.csv` probado en la prueba del core).
- **Selección de hoja**: el núcleo acepta `hoja:` (índice o nombre); la CLI gana
  `--hoja N|nombre` y `--listar-hojas`; la GUI añade un desplegable **Hoja** que se
  actualiza al elegir archivo.
- **Omisión de filas completamente vacías** en la hoja.
- **Rakefile** con tareas `test`, `cli`, `gui` (por defecto `test`).
- Fixture `data/demo/codigos_dos_hojas.xlsx` (hojas Principal/Secundaria + fila vacía)
  y ampliación de `_scripts/dev/prueba_core.rb`.
- **Suite de tests minitest** `test/generador_etiquetas_test.rb` (22 casos:
  validación/Code128, dimensiones, composición, lectura y máquina completa);
  `rake test` ejecuta suite + smoke test.

## [1.0.0] - 2026-09-12

### Añadido
- **Núcleo del sistema reconstruido** en `lib/generador_etiquetas/` independiente de la
  GUI: `dimensiones`, `etiqueta`, `libro` (Roo), `layout`, `dibujo`, `pdf`, `reporte`,
  `maquina` y el require central `lib/generador_etiquetas.rb`.
- **GUI con panel de resultados** (`lib/gui/aplicacion.rb`): tabla de estados
  (generada / duplicada / inválida / error), **vista previa de la etiqueta** (Cairo,
  misma geometría que el PDF) y acción "Abrir el PDF generado".
- **CLI portátil** `bin/etiquetas_cli` con `--salida`, `--buscar`, `--cantidad`,
  `--todas`, `--ancho-mm`, `--alto-mm`, `--quiet` y `--help`.
- **Fixtures demo adicionales**: `data/demo/codigos_con_problemas.xlsx` (encabezado,
  duplicados y código no imprimible) y ampliación de la prueba del core
  (`_scripts/dev/prueba_core.rb`) con verificación de tamaño (100×50 mm), texto y
  caminos negativos.
- Variantes históricas conservadas en `lib/legacy/`.

### Corregido
- **Tamaño de etiqueta**: la versión histórica generaba PDFs de 75×28 pt (≈26×10 mm);
  ahora el tamaño por defecto es **100×50 mm (283.46×141.73 pt)** — verificado.
- **Dibujo de barras**: se abandonó `Barby::Code128#annotate_pdf` (posición/altura
  incorrectas) por dibujo manual de módulos a partir de `#encoding`, compartido entre
  PDF y vista previa.
- **Posicionamiento de texto en Prawn**: `fill_rectangle`/`text_box` se desplazan desde
  el borde superior; todas las conversiones se expresan en coordenadas top-down y se
  convierten al escribir (la primera versión invertía el eje vertical de las barras).

### Mejorado
- Un solo `LayoutEtiqueta.calcular` alimenta PDF (Prawn) y vista previa (Cairo):
  "lo que se ve es lo que se imprime".
- Reportes por fila (estado, código, descripción, archivo/error) y totales.
- Deduplicación por código y omisión automática de la cabecera de la hoja.

## [0.2.0] - 2026-08-31

### Corregido
- Búsqueda de códigos en la variante CLI: se reemplazó `xlsx.each` por una iteración
  explícita por filas y primera columna usando la API de Roo (`first_row..last_row` +
  `cell(row_index, 1)`), normalizando mayúsculas/minúsculas.
- Eliminación de rutas Windows rígidas (`C:\...`) en la CLI: ejecución portable.

### Mejorado
- Ejecución portable (rutas relativas a `__dir__` / argumentos).
- Estabilización de la GUI principal (`bin/main.rb`): flujo verificado en Linux/X11
  (selección de archivo, cantidad de etiquetas y generación de PDFs).
- Capturas reales de la ejecución añadidas en `assets/`.

## [0.1.0] - 2026-08-31

### Añadido
- Publicación inicial del generador de etiquetas recuperado de material histórico
  (enero–febrero 2024, PernoStock Ltda.).
- Entrada principal modular (`lib/main.rb`) que genera N etiquetas desde la primera
  columna de una hoja de cálculo y las exporta a PDF (Code128 via Barby + Prawn).
- Variantes conservadas: GTK con buscador por código, CLI, versión simple y prototipo Shoes.
- Documentación: dependencias (`docs/gems.txt`), planificación/funcionalidades originales
  y referencia del predecesor en VB.
- **Exclusión de datos sensibles:** los Excel originales con datos comerciales (lista
  maestra de precios y libro de recepción de baterías) se conservan solo en el material
  histórico local y no se publican en este repositorio.
