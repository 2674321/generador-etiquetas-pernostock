# PROJECT.md — Generador de Etiquetas

## Nombre

Generador de Etiquetas

## Empresa / contexto

**PernoStock Ltda.**

> Software histórico recuperado de material de trabajo de PernoStock Ltda.
> (enero–febrero 2024, proyecto de formación en Técnico en Programación).
> Se preserva como referencia histórica; no representa software en uso actual
> por la empresa.

## Estado

- Código recuperado y publicado: **estable / histórico**.
- Preparación DEV para ejecutarlo en el PC actual: **completa**.
- Core funcional (Excel → códigos Code128 → PDF) verificado con datos demo ficticios.

## Versión

`0.1.0` (público). Histórico original: versión no determinada (variantes `main`, GTK, CLI, simple, Shoes).

## Runtime

- Ruby **3.2.x** (originalmente desarrollado sobre 3.2.x; reproducible con mise en 3.2).
- GUI: **GTK3** (`gtk3` gem).
- Sistema operativo originalmente objetivo: **Windows** (rutas `C:\` en variantes CLI). En Linux, la variante GTK (`bin/main.rb`) funciona con display X11.

## Entrypoint

- **GTK (principal funcionando en Linux):** `bin/main.rb` → `ruby bin/main.rb`
  - Genera N etiquetas a partir de la primera columna de un `.xlsx`/`.xls`.
- Variante GTK con buscador: `lib/generador_etiquetas_gtk.rbw`
- Variante CLI: `lib/generador_etiquetas_cli.rb` (rutas Windows fijas — requiere ajuste).
- Variantes: `lib/generador_etiquetas_simple.rb`, `lib/visual_shoes.rb`.

## Repositorio

- GitHub: https://github.com/2674321/generador-etiquetas-pernostock
- Local: carpeta `generador-etiquetas-pernostock/`.

## Dependencias (gems)

`gtk3`, `prawn`, `roo`, `roo-xls`, `barby`, `tty-progressbar`.

## Cómo probar

Ver `docs/DEV-SETUP.md`. Resumen:

```bash
cd generador-etiquetas-pernostock
mise install          # asegura Ruby 3.2
bundle install
ruby bin/main.rb      # GUI GTK (requiere display X11)
```

Prueba headless del core (con datos demo ficticios):

```bash
mise exec -- ruby _scripts/dev/prueba_core.rb
```

## Notas / problemas conocidos

- Las variantes CLI/`simple` usan rutas fijas `C:\...`; en Linux se deben ajustar.
- `*.xlsx`/`*.xls` con datos reales de PernoStock NO se versionan (ver `.gitignore`).
- La GUI requiere un entorno gráfico X11 (probado en `DISPLAY=:0`).
