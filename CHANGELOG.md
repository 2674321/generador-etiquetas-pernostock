# Changelog

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
