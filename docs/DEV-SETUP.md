# DEV-SETUP.md — Generador de Etiquetas (PernoStock Ltda.)

Guía para reproducir el entorno de desarrollo y ejecutar el Generador de Etiquetas
en el PC actual (Linux con X11), usando **mise** para la versión de Ruby.

> Software histórico recuperado de material de trabajo de **PernoStock Ltda.**
> No representa software en uso actual por la empresa.

## Requisitos

- Linux con display X11 (probado en `DISPLAY=:0`).
- GTK3 y librerías nativas de desarrollo (para build de `gtk3` gem):
  ```bash
  sudo apt install libgtk-3-dev libgirepository1.0-dev build-essential pkg-config
  ```
  (En este PC ya están presentes: `libgtk-3-dev` 3.24 instalado. `cairo` viene con GTK.)
- [mise](https://mise.jdx.dev) instalado.

## Versión de Ruby

- **Requerida:** Ruby 3.2.x (el `Gemfile` declara `ruby '>= 3.0'`; el README histórico
  indica 3.2.x).
- **Instalada por mise:** Ruby 3.2.11 (resuelta por `.ruby-version` = `3.2`).

## Versión de gems

Definidas en `Gemfile`:

| Gem | Finalidad |
|---|---|
| `gtk3` | Interfaz gráfica GTK3 |
| `cairo` | Vista previa de la etiqueta (dibujo) |
| `prawn` | Generación de PDF |
| `roo` / `roo-xls` | Lectura de hojas de cálculo `.xlsx` / `.xls` / `.xlsm` / `.ods` |
| `barby` | Códigos de barras Code128 (solo `#encoding`) |
| `tty-progressbar` | Barra de progreso (variantes históricas) |

## Instalación

Dentro de la carpeta del proyecto:

```bash
cd generador-etiquetas-pernostock
mise install          # asegura Ruby 3.2 (usa .ruby-version)
bundle install        # instala las gems en la Ruby de mise
```

## Ejecución

```bash
# GUI con panel de resultados (requiere display X11)
mise exec -- bundle exec ruby bin/main.rb

# CLI portátil (100×50 mm por defecto; salida en ./salida)
mise exec -- bundle exec ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx
mise exec -- bundle exec ruby bin/etiquetas_cli data/demo/codigos_demo.csv --hoja 0
mise exec -- bundle exec ruby bin/etiquetas_cli --help
```

> Requiere un entorno gráfico solo para la GUI. La CLI y el núcleo son headless.

## Prueba básica (sin datos reales)

1. Los fixtures con códigos ficticios (`data/demo/codigos_demo.xlsx` y
   `codigos_con_problemas.xlsx`) se generan/regeneran según las instrucciones de
   `data/demo/` (los `.xlsx` no se versionan).
2. Prueba del core sin GUI:

```bash
mise exec -- ruby _scripts/dev/prueba_core.rb
```

Salida esperada: `PRUEBA DEL CORE: CORRECTA`. Genera los 5 PDFs demo, comprueba su
tamaño (100×50 mm = `/MediaBox [0 0 283.46 141.73]`), verifica el texto de cada PDF y
ejercita encabezado, duplicados y código no imprimible.

## Validación sintáctica

```bash
mise exec -- ruby -c bin/main.rb
mise exec -- ruby -c bin/etiquetas_cli
for f in lib/generador_etiquetas.rb lib/generador_etiquetas/*.rb lib/gui/*.rb; do
  mise exec -- ruby -c "$f" >/dev/null || echo "FALLA: $f"
done
```

## Verificación de rutas portables

No deben quedar rutas Windows rígidas en el código fuente:

```bash
grep -RniE 'C:\\|C:/|Users/|Desktop/' bin lib
```

## Capturas reales

La GUI se probó con `data/demo/codigos_demo.xlsx` (Linux/X11). Capturas en `assets/`:
`generador_etiquetas_gtk_principal.png`, `generador_etiquetas_generacion.png`,
`generador_etiquetas_resultado.png`.

## Problemas conocidos

- **MENOR:** la vista previa (Cairo) usa métricas aproximadas para el texto: las
  **barras** coinciden exactamente con el PDF, pero los textos pueden variar ±1–2 pt
  en posición (solo visual; el PDF impreso es el que manda).
- **HISTÓRICO:** las variantes en `lib/legacy/` conservan sus limitaciones (p. ej.
  `xlsx.each`, tamaño 75×28 pt). Solo se mantienen como referencia.
- **HISTÓRICO:** la app fue creada para Windows/RubyDevkit 3.2.2; en Linux la GUI
  `bin/main.rb` (reconstruida) funciona con X11.
