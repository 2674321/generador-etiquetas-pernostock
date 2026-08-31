# Generador de Etiquetas — PernoStock Ltda.

Aplicación de escritorio en **Ruby + GTK3** para generar etiquetas de códigos de
barras (Code128) en PDF, leyendo los códigos desde una hoja de cálculo (Excel).

> **⚠️ Software recuperado de material histórico de trabajo** (enero–febrero 2024).
> Fue desarrollado como parte de un proyecto de formación (Técnico en Programación)
> para **PernoStock Ltda.** Se publica como referencia histórica y para preservar el
> código; no representa el estado actual del desarrollo.

## Funcionalidades

- Lee una hoja de cálculo (`.xlsx` / `.xls`) y genera códigos de barras Code128.
- **`main.rb` (principal):** genera N etiquetas a partir de la primera columna de la hoja
  de cálculo y las guarda en PDF en la carpeta `pdfs/`.
- **`generador_etiquetas_gtk.rbw`:** interfaz GTK con buscador por código, selector de
  archivo de entrada y carpeta de salida.
- Variantes de desarrollo (CLI, versión simple, prototipo Shoes).

## Stack

| Componente | Tecnología |
|---|---|
| Lenguaje | Ruby 3.2.x |
| GUI | GTK3 |
| Código de barras | Barby (Code128) |
| PDF | Prawn |
| Lectura de Excel | roo-xls / roo |

## Estructura

```
├── bin/main.rb                 ← punto de entrada (wrapper)
├── lib/
│   ├── main.rb                 ← generador principal (modular, N etiquetas)
│   ├── generador_etiquetas_gtk.rbw   ← variante GTK con buscador por código
│   ├── generador_etiquetas_cli.rb    ← variante por consola (CLI)
│   ├── generador_etiquetas_simple.rb ← variante simple
│   └── visual_shoes.rb         ← prototipo (Shoes)
├── docs/
│   ├── gems.txt                ← dependencias y comandos de instalación
│   ├── Funciones_2_programas.txt    ← planificación/características
│   ├── codigo_etiquetas_VB.txt → referencia de la versión VB original
│   └── codigo_barras_unico_ejemplo.pdf ← ejemplo de salida
├── Gemfile
└── CHANGELOG.md
```

## Instalación

```bash
mise install        # asegura Ruby 3.2 (usa .ruby-version)
bundle install      # instala las gems declaradas en el Gemfile
```

## Ejecución (CLI)

```bash
mise exec -- bundle exec ruby lib/generador_etiquetas_cli.rb data/demo/codigos_demo.xlsx [directorio_salida]
```

La CLI acepta el archivo de entrada como argumento (ruta relativa o absoluta) y
escribe el PDF en el directorio de salida (por defecto `salida/` dentro del
proyecto). Sin argumento muestra la ayuda de uso.

## Ejecución (GUI)

```bash
mise exec -- bundle exec ruby bin/main.rb   # GUI GTK (requiere display X11)
```

> **Entorno DEV:** la reproducción en este PC (Linux/X11, Ruby 3.2 vía mise) está
> verificada — ver [`docs/DEV-SETUP.md`](docs/DEV-SETUP.md). El core
> (Excel → Code128 → PDF) se probó con datos demo ficticios (`_scripts/dev/prueba_core.rb`).

> Las rutas de entrada/salida son **portables** (no dependen de rutas Windows fijas).

## Datos de ejemplo

Este repositorio **no incluye** los archivos Excel originales (lista maestra de precios y
libro de recepción de baterías), que contienen datos comerciales sensibles de PernoStock
Ltda. y se conservan únicamente en el material histórico local. Para probar, usa una hoja
de cálculo propia con los códigos en la primera columna.

## Autor

**Patricio Varela C.** (CA2OPX) · [ORCID 0009-0002-1087-9445](https://orcid.org/0009-0002-1087-9445) · [github.com/2674321](https://github.com/2674321)

## Licencia

MIT — ver [LICENSE](LICENSE).
