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
  (En este PC ya están presentes: `libgtk-3-dev` 3.24 instalado.)
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
| `prawn` | Generación de PDF |
| `roo` / `roo-xls` | Lectura de hojas de cálculo `.xlsx` / `.xls` |
| `barby` | Códigos de barras Code128 |
| `tty-progressbar` | Barra de progreso (variantes) |

## Instalación

Dentro de la carpeta del proyecto:

```bash
cd generador-etiquetas-pernostock
mise install          # asegura Ruby 3.2 (usa .ruby-version)
bundle install        # instala las gems en la Ruby de mise
```

## Ejecución

```bash
# GUI principal (genera N etiquetas desde la 1ª columna del Excel)
mise exec -- bundle exec ruby bin/main.rb
```

> Requiere un entorno gráfico. Probado con `DISPLAY=:0`.

### Variantes

```bash
# GTK con buscador por código
mise exec -- bundle exec ruby lib/generador_etiquetas_gtk.rbw

# CLI (rutas Windows fijas C:\... — requiere ajuste en Linux)
mise exec -- bundle exec ruby lib/generador_etiquetas_cli.rb
```

## Prueba básica (sin datos reales)

1. El fixture con códigos ficticios (`data/demo/codigos_demo.xlsx`) se genera según
   instrucciones en `data/demo/` (los `.xlsx` no se versionan).
2. Prueba del core sin GUI:

```bash
mise exec -- ruby _scripts/dev/prueba_core.rb
```

Salida esperada: lee los códigos demo y crea 5 PDFs (Code128) en `tmp/demo_pdfs/`.

## Validación sintáctica

```bash
mise exec -- ruby -c bin/main.rb
mise exec -- ruby -c lib/main.rb
mise exec -- ruby -c lib/generador_etiquetas_gtk.rbw
mise exec -- ruby -c lib/generador_etiquetas_cli.rb
```

## Problemas conocidos

- **IMPORTANTE:** las variantes CLI/simple usan rutas fijas `C:\...`; en Linux hay que
  ajustar las constantes de entrada/salida.
- **MENOR:** la constante `Gtk::VERSION` no existe en `gtk3` 4.3.8 (es `Gtk::Version`).
  No afecta la ejecución.
- **HISTÓRICO:** la app fue creada para Windows/RubyDevkit 3.2.2; en Linux la variante
  GTK `bin/main.rb` funciona con X11.
