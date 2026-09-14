# Contribuir a PernoLabel

Gracias por tu interés en este proyecto de portafolio. Es pequeño y local, pero
cualquier aporte se agradece.

## Cómo aportar

1. Abre un *issue* describiendo el problema o la idea (bug, mejora, pregunta).
2. Si vas a tocar código:
   - Mantén `bin/pernolabel` (CLI), el núcleo `lib/generador_etiquetas/` (sin
     GUI) y la GUI `lib/gui/` desacoplados.
   - No rompas los fixtures demo ficticios (`data/demo/`, sin datos reales de
     PernoStock).
   - Añade o actualiza pruebas en `test/generador_etiquetas_test.rb` y el
     smoke del núcleo `_scripts/dev/prueba_core.rb`.
3. Pasa la suite antes de pedir el *review*:

```bash
rake test                      # minitest + smoke del core (sin GUI)
rake gui_smoke                 # solo si hay DISPLAY (X11)
```

## Guía de estilo

- Ruby, `frozen_string_literal: true`, sin comentarios salvo los docblocks de
  API y secciones.
- Comentarios y textos de interfaz en español.
- Rangos de hojas (fila/columna) van por números reales del origen (Roo).

## Estructura clave

```
lib/generador_etiquetas/   NÚCLEO (portable, sin GTK)
  detector_columnas.rb     localiza columnas y encabezado
  libro.rb                 lectura (XLSX/XLS/ODS/CSV vía roo)
  maquina.rb               orquestador seprocesar
  layout.rb, dibujo.rb     geometría y dibujo de etiqueta/lote
  pdf.rb                   destino PDF (Prawn)
  cli.rb                   interfaz de consola
lib/gui/                   GUI GTK (solo aquí se usa gtk3/cairo)
data/demo/                 fixtures ficticios de prueba
packaging/                 iniciador de escritorio e icono
```