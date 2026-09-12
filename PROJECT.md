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
- **Reconstrucción del sistema (2026-09-12):** núcleo portátil sin GUI, etiquetas
  corregidas a tamaño real (100×50 mm) y GUI con **panel de resultados + vista previa**.
- Core funcional (hoja de cálculo → códigos Code128 → PDF) verificado sin GUI con
  datos demo ficticios (`_scripts/dev/prueba_core.rb`).

## Versión

`v1.2.0` (reconstrucción con correcciones + selección de hoja + CSV + progreso y
metadatos + lote A4 imprimible con margen/hueco configurables + vista previa de
la cuadrícula en la GUI + GUI verificada headful). Histórico original: versión no
determinada (variantes `main`, GTK, CLI, simple, Shoes → conservadas en
`lib/legacy/`).

## Runtime

- Ruby **3.2.x** (originalmente desarrollado sobre 3.2.x; reproducible con mise en 3.2.11).
- GUI: **GTK3** (`gtk3` gem).
- Sistema operativo originalmente objetivo: **Windows**. En esta iteración se convirtieron
  las rutas rígidas `C:\...` en rutas **portables** (argumento de CLI, `__dir__`), y la
  ejecución reproducible quedó verificada en **Linux (X11)** con datos demo.

## Entrypoint

- **GUI (requiere display X11):** `ruby bin/main.rb` → `lib/gui/aplicacion.rb`
  - Panel de resultados (tabla de estados) + vista previa Cairo, selector de hoja de
    cálculo, filtro, cantidad, duplicados y tamaño en mm.
- **CLI portátil:** `ruby bin/etiquetas_cli` → `lib/generador_etiquetas/cli.rb`
  - Opciones `--salida`, `--buscar`, `--cantidad`, `--todas`, `--ancho-mm`, `--alto-mm`.
- **Núcleo (headless):** `lib/generador_etiquetas.rb` — usado por GUI y CLI.

## Repositorio

- GitHub: https://github.com/2674321/generador-etiquetas-pernostock
- Local: carpeta `generador-etiquetas-pernostock/`.

## Dependencias (gems)

`gtk3`, `cairo` (vista previa), `prawn`, `roo`, `roo-xls`, `barby`, `tty-progressbar`.

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

- La vista previa (Cairo) usa métricas de fuente aproximadas; las **barras** coinciden
  exactamente con el PDF, y el texto puede variar ±1–2 pt en posición (solo visual).
- La GUI requiere un entorno gráfico X11 (probada en `DISPLAY=:0`).
- `*.xlsx`/`*.xls` con datos reales de PernoStock NO se versionan (ver `.gitignore`).
- Las variantes históricas (GTK con buscador, simple, Shoes, CLI antigua) siguen en
  `lib/legacy/` y conservan sus limitaciones conocidas (p. ej. `xlsx.each`).
