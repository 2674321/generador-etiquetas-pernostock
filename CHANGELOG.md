# Changelog

## [1.4.0] - 2026-09-12

### Añadido
- **Código QR como tipo seleccionable** (`rqrcode`): `LayoutEtiqueta` admite
  `TIPO_CODE128=:code128`, `TIPO_QR=:qr` y `TIPO_AMBOS=:ambos` (barras a la
  izquierda + QR a la derecha, `QR_ANCHO_BASE` 0.32 y separación 4 pt). El QR
  codifica el mismo código de producto (nivel M). `Etiqueta#qr_modules` expone la
  matriz 21×21 para dibujado compartido (PDF/Cairo).
- **Opciones de código en CLI** (`--codigo code128|qr|ambos`, alias `barras`),
  **GUI** (desplegable "Código:") y **API** (`tipo_codigo:` en
  `Maquina#procesar/#generar_pdf/#generar_lote`, `PdfEtiqueta.generar`,
  `LoteEtiqueta.generar`, `LayoutEtiqueta.calcular`, `PanelHoja`). `normalizar_tipo`
  valida el valor y lanza `ArgumentError` si es desconocido (el CLI lo reporta).
- **Rebranding de producto a PernoLabel**: CLI renombrado a `bin/pernolabel`
  (con `bin/etiquetas_cli` como alias de compatibilidad), `--version` imprime
  `PernoLabel 1.4.0`, autor del PDF `PernoLabel`, título de ventana
  "PernoLabel — Etiquetas Pernostock" y nombres de producto en la documentación.
  El núcleo conserva el espacio de nombres `GeneradorEtiquetas`.
- Docs actualizadas: README (QR, estructura, CLI, GUI), PROJECT, DEV-SETUP,
  `docs/gems.txt` (rqrcode).

## [1.3.0] - 2026-09-12

### Añadido
- **Hoja del lote personalizada**: `--lote-pagina ANCHOxALTO` (mm) en el CLI y
  `Maquina#procesar(lote_pagina_pt: [ancho, alto])` en la API. La cuadrícula y el
  PDF se ajustan al tamaño pedido; en el reporte, la descripción del lote indica
  la hoja cuando no es A4 (p. ej. `5 etiquetas · hoja 150.0×100.0 mm`).
- **Paginación de la vista previa del lote** en la GUI: `PanelHoja` acepta
  `pagina:` (0-based), expone `paginas`/`margen_pt`/`hueco_pt` y muestra las
  etiquetas de la página elegida. Al seleccionar la fila "LOTE A4" aparece un
  selector **"Pág. del lote"** (solo visible si hay más de una hoja) y el pie
  indica "Página N de M".
- **Margen y separación del lote editables en la GUI**: dos spinners
  "Sep. lote (mm)" y "Margen (mm)" junto a la casilla "Lote A4"; se pasan a la
  máquina y a la vista previa (lote y página se recalculan al cambiar).
- Núcleo: helpers `LoteEtiqueta.por_hoja` y `LoteEtiqueta.paginas`.
- Tests: `TestLotePaginas` (nº de páginas, por_hoja), `TestPanelHoja`
  (multi-página, página vacía, dibujo por página), `lote con página
  personalizada` en `TestMaquina`; sonda GUI ampliada a **19 comprobaciones**
  (spinners de lote, margen→previa, 2 páginas con 8 etiquetas, dibujo de la
  página 2).

## [1.2.0] - 2026-09-12

### Añadido
- **Vista previa de la hoja A4** en la GUI: al seleccionar la fila "LOTE A4" el
  panel muestra la cuadrícula de la **primera página** del lote, dibujando cada
  etiqueta con la misma composición que el PDF (nuevo `PanelHoja` que reutiliza
  `LoteEtiqueta.grarilla`/`celda` + `DibujoEtiqueta`). La fila del lote ya podía
  abrirse con el botón (ahora `abrir_pdf_seleccionado` también la admite).
- **Margen y hueco del lote configurables**:
  - CLI: `--lote-margen-mm MM` (defecto 20) y `--lote-hueco-mm MM` (defecto 8).
  - API: `Maquina#procesar(lote: true, lote_margen_pt: n, lote_hueco_pt: n)`.
  - La cuadrícula se recalcula en consecuencia (la GUI muestra la misma
    geometría en la previa).
- Tests: configurabilidad de `grarilla` (margen/hueco reducen columnas) y
  `Maquina` con margen/hueco a medida; sonda GUI ampliada a 15 comprobaciones
  (selección de la fila LOTE, previa de hoja y dibujo offscreen de la cuadrícula).

## [1.1.0] - 2026-09-12

### Añadido
- **Lote A4 imprimible**: `Libro → Maquina(lote: true) → lote_A4.pdf` con todas las
  etiquetas generadas en una cuadrícula sobre hojas A4 (varias hojas si no caben).
  Reutiliza `LayoutEtiqueta` + `DibujoEtiqueta` + `DibujadorPdf` (con origen), por lo
  que cada celda del lote tiene la misma composición que el PDF individual.
  - Nuevo módulo `LoteEtiqueta` (`lib/generador_etiquetas/lote.rb`): `grarilla`,
    `celda` y `generar` (márgenes/hueco configurables; A4 210×297 mm por defecto).
  - `DibujadorPdf` acepta ahora `origen_x:/origen_y:` (top-down) para dibujar en
    cualquier celda de una hoja.
  - CLI: opción `--lote`; fila `LOTE` en el reporte (con su ruta) y resumen
    "Hoja A4 de lote".
  - GUI: casilla **"Lote A4"** en la barra de opciones; la fila LOTE se lista en
    resultados (su selección abre el lote; sin vista previa de etiqueta simple).
  - Tests: 4 casos minitest de la cuadrícula + verificación A4 en el smoke test
    (`pdfinfo`/`pdftotext`: MediaBox 595.28×841.89 y los 5 códigos presentes);
    sonda GUI ampliada a 9 comprobaciones (incluye lote).

## [1.0.3] - 2026-09-12

### Añadido
- **`rake gui_smoke`**: sonda headful de la GUI (`_scripts/dev/gui_smoke.rb`, requiere
  `DISPLAY`) que construye la ventana sin mostrarla y valida selección de archivo,
  selector de hoja, generación en hilo, resultados en el TreeView, `actualizar_previa`
  y la previa Cairo. Pasó en este entorno (8/8).
- **Refresco defensivo de hojas** en `generar()`: si el selector sigue en "(1ª hoja)",
  se repuebla antes de leer la hoja activa.

### Corregido
- `Gtk::CheckButton.new('Incluir duplicados')`: la introspección de gtk3 exigía el
  label posicional (crasheaba el arranque de la GUI con `label:`).

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
