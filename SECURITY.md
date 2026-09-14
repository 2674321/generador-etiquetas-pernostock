# Seguridad

## Reportar una vulnerabilidad

Este es un proyecto de portafolio y no maneja datos sensibles por sí mismo; sin
embargo, si encuentras un problema de seguridad:

- **No** abras un *issue* público con detalles explotables.
- Envía un correo corto por GitHub (edita una vulnerabilidad vía *Security
  advisories*) o abre un *issue* genérico describiendo el área afectada sin
  detalles técnicos.

## Contexto

- El repositorio **no incluye** los libros comerciales originales de PernoStock
  (lista maestra de precios ni recepción de baterías). Los fixtures de `data/demo/`
  son ficticios.
- La app lee hojas de cálculo del usuario y escribe PDFs locales; no hay red ni
  telemetría.
- El archivo `.gitignore` excluye deliberadamente `*.xlsx`/`*.xls` y `*.pdf`
  generados, para no filtrar datos propietarios.