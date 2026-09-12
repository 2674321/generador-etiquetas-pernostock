# Generador de Etiquetas — PernoStock Ltda.

Aplicación de escritorio en **Ruby + GTK3** para generar etiquetas de códigos de
barras (Code128) en PDF (100×50 mm), leyendo los códigos desde una hoja de cálculo
(Excel/ODS).

> **⚠️ Software recuperado de material histórico de trabajo** (enero–febrero 2024).
> Fue desarrollado como parte de un proyecto de formación (Técnico en Programación)
> para **PernoStock Ltda.** El repositorio se publica como referencia y para preservar
> el código; esta iteración además **reconstruye el sistema** con un núcleo portátil,
> etiquetas a tamaño real corregidas y un panel de resultados en la GUI.

## Características

- **Núcleo independiente de la GUI** (`lib/generador_etiquetas/`): lee la hoja de
  cálculo, valida códigos, calcula el layout y genera PDFs. Portable y sin dependencias
  de escritorio.
- **Etiquetas a tamaño real (100×50 mm)**: la geometría (descripción, barras y código
  legible) se calcula una única vez en `LayoutEtiqueta` y alimenta **tanto el PDF como
  la vista previa**, de modo que lo que se ve es exactamente lo que se imprime.
  *(Se corrige la versión histórica, que generaba etiquetas de solo 75×28 pt.)*
- **GUI (`bin/main.rb`)** con:
  - Selector de hoja de cálculo, filtro por texto, cantidad máxima, inclusión de
    duplicados y tamaño configurable (mm).
  - **Panel de resultados**: tabla con estado (generada / duplicada / inválida /
    error / **lote**) y **vista previa** de la etiqueta seleccionada o de la
    **primera hoja del lote** (dibujada con Cairo, misma geometría que el PDF).
  - Acción "Abrir el PDF generado" para cada fila.
- **CLI portátil (`bin/etiquetas_cli`)** con opciones `--salida`, `--buscar`,
  `--cantidad`, `--hoja N|nombre`, `--listar-hojas`, `--todas`, `--ancho-mm`,
  `--alto-mm`, `--lote`, `--lote-margen-mm`, `--lote-hueco-mm`,
  `--lote-pagina ANCHOxALTO`, `--quiet`, barra de **progreso** en terminal y
  resumen con tiempo.
- **PDFs con metadatos** (código/descripción/versión) y **vista previa** en la GUI
  con la misma geometría que se imprime.
- **Lote**: `--lote` (CLI) o casilla **"Lote A4"** (GUI) genera `lote_A4.pdf`,
  hoja imprimible con todas las etiquetas en cuadrícula (varias páginas si no
  caben). Configurables: **hoja** (`--lote-pagina ANCHOxALTO`, deg. A4),
  **margen** (`--lote-margen-mm`, def. 20) y **separación** entre etiquetas
  (`--lote-hueco-mm`, def. 8).
- **Vista previa paginada del lote** en la GUI: al seleccionar la fila "LOTE A4"
  se dibuja la cuadrícula de una página exactamente como el PDF, con un selector
  **"Pág. del lote"** cuando hay más de una hoja.
- **Deduplicación** por código (se omite en el PDF; se informa en el reporte),
  **validación Code128** (solo ASCII imprimible), **omisión automática de la cabecera**
  y de **filas vacías** de la hoja, y **selección de hoja** (GUI/CLI).
- Las variantes históricas se conservan en `lib/legacy/`.

## Stack

| Componente | Tecnología |
|---|---|
| Lenguaje | Ruby 3.2.x |
| GUI | GTK3 (+ Cairo para la vista previa) |
| Código de barras | Barby (Code128, dibujo de módulos manual) |
| PDF | Prawn |
| Lectura de hoja | roo / roo-xls (`.xlsx`, `.xls`, `.xlsm`, `.ods`, `.csv`) |

## Estructura

```
├── Rakefile                     ← rake test / cli / gui
├── bin/
│   ├── main.rb                    ← GUI (requiere display X11)
│   └── etiquetas_cli              ← CLI portátil
├── lib/
│   ├── generador_etiquetas.rb     ← require central del núcleo
│   ├── generador_etiquetas/       ← NÚCLEO (sin GUI)
│   │   ├── dimensiones.rb         ← geometría y conversión mm→pt
│   │   ├── etiqueta.rb            ← modelo y validación del código
│   │   ├── libro.rb               ← lectura de la hoja (Roo)
│   │   ├── layout.rb              ← composición de la etiqueta (top-down)
│   │   ├── dibujo.rb              ← flujo de dibujo compartido
│   │   ├── pdf.rb                 ← destino PDF (Prawn)
│   │   ├── reporte.rb             ← resultados por fila y totales
│   │   ├── maquina.rb             ← orquestador (procesar → PDFs+reporte)
│   │   └── cli.rb                 ← interfaz de consola
│   ├── gui/
│   │   ├── aplicacion.rb          ← ventana con panel de resultados
│   │   └── panel_etiqueta.rb      ← destino de vista previa (Cairo)
│   └── legacy/                    ← variantes históricas conservadas
├── data/demo/                     ← fixtures ficticios (no versionados)
└── docs/
    ├── gems.txt                   ← dependencias y requires
    ├── DEV-SETUP.md               ← reproducción del entorno
    ├── Funciones_2_programas.txt  ← planificación/características
    └── codigo_etiquetas_VB.txt    ← referencia de la versión VB original
```

## Instalación

```bash
mise install        # asegura Ruby 3.2 (usa .ruby-version)
bundle install      # instala las gems declaradas en el Gemfile
```

## Ejecución (CLI)

```bash
ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx
ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx --salida salida --buscar PET-10
ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx --listar-hojas
ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx --hoja Secundaria
ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx --lote
ruby bin/etiquetas_cli --help
```

Escribe los PDF en `./salida` por defecto (portable). Muestra un reporte por fila y
un resumen al final.

## Ejecución (GUI)

```bash
ruby bin/main.rb   # GUI GTK (requiere display X11)
```

Flujo:
1. Seleccionar la hoja de cálculo o CSV (`.xlsx` / `.xls` / `.xlsm` / `.ods` / `.csv`).
2. Con la hoja de **Hoja** elegir si se desea (se actualiza al cambiar el archivo).
3. Ajustar opciones (filtro, cantidad, duplicados, tamaño en mm, **lote con su
   margen/separación**) y pulsar **Generar etiquetas**.
4. En el **panel de resultados**, cada fila muestra su estado; al seleccionarla se dibuja
   la **vista previa** (misma geometría que el PDF) y se puede abrir el PDF generado.

> **Entorno DEV:** la reproducción en este PC (Linux/X11, Ruby 3.2 vía mise) está
> verificada — ver [`docs/DEV-SETUP.md`](docs/DEV-SETUP.md). El core
> (hoja → Code128 → PDF) se prueba sin GUI con `_scripts/dev/prueba_core.rb`.

## Prueba del core (headless)

```bash
rake test            # suite minitest + smoke test del core
ruby _scripts/dev/prueba_core.rb
```

La suite `test/generador_etiquetas_test.rb` (minitest) cubre validación y Code128,
dimensiones, composición, lectura (XLSX/CSV/hojas/filas vacías) y la máquina completa.
El smoke test genera los 5 PDFs demo, comprueba que son 100×50 mm, verifica el contenido
textual de cada PDF y ejercita los caminos negativos (encabezado, duplicados, código no
imprimible, selección de hoja y CSV).

## Datos de ejemplo

Este repositorio **no incluye** los archivos Excel originales (lista maestra de precios y
libro de recepción de baterías), que contienen datos comerciales sensibles de PernoStock
Ltda. y se conservan únicamente en el material histórico local. Para probar se usan
fixtures ficticios (`data/demo/`), regenerables sin datos reales.

## Autor

**Patricio Varela C.** (CA2OPX) · [ORCID 0009-0002-1087-9445](https://orcid.org/0009-0002-1087-9445) · [github.com/2674321](https://github.com/2674321)

## Licencia

MIT — ver [LICENSE](LICENSE).