# data/demo — Fixtures de prueba (ficticios)

Este repositorio **no incluye** los archivos Excel originales de PernoStock Ltda.
Los fixtures de esta carpeta son **ficticios** y están **versionados** (el
`.gitignore` exime `data/demo/*.xlsx`), de modo que `rake test` funciona en un
clon limpio y en el CI sin regenerar nada.

| Archivo | Contenido |
|---|---|
| `codigos_demo.xlsx` | 5 productos, sin encabezado (columna A=código, B=descripción) |
| `codigos_demo.csv` | igual que el de problemas en CSV (encabezado + duplicados + inválida) |
| `codigos_con_problemas.xlsx` | encabezado, 2 duplicados y 1 código no imprimible |
| `codigos_dos_hojas.xlsx` | hojas "Principal" (con fila vacía) y "Secundaria" |
| `codigos_invertidos.csv` | descripción antes que código, con encabezado |
| `codigos_sin_encabezado_invertido.csv` | descripción antes que código, sin encabezado |
| `codigos_extra.csv` | columna "Existencias" entre código y descripción |

Para regenerar los `.xlsx` ficticios (equivalente a los versionados):

```bash
python3 - <<'PY'
import openpyxl
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Codigos"
ws.append(["PET-1001", "BATERIA DEMO 001"])
ws.append(["PET-1002", "BATERIA DEMO 002"])
ws.append(["PET-1003", "BATERIA DEMO 003"])
ws.append(["PET-1004", "BATERIA DEMO 004"])
ws.append(["PET-1005", "BATERIA DEMO 005"])
wb.save("data/demo/codigos_demo.xlsx")

# Fixture para caminos negativos (encabezado + duplicados + código no imprimible)
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Codigos"
ws.append(["Código", "Descripción"])
ws.append(["PET-1001", "BATERIA DEMO 001"])
ws.append(["PET-1001", "BATERIA DEMO 001 DUP"])
ws.append(["PET-2001", "Cambio 2001"])
ws.append(["PET-2001", "Cambio 2001 DUP"])
ws.append(["PET-Ñ001", "código con ñ NO imprimible"])
wb.save("data/demo/codigos_con_problemas.xlsx")

# Fixture con dos hojas + una fila vacía (para --hoja / --listar-hojas)
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Principal"
ws.append(["Código", "Descripción"])
ws.append(["PET-1001", "BATERIA DEMO 001"])
ws.append([None, None])
ws.append(["PET-1002", "BATERIA DEMO 002"])
ws2 = wb.create_sheet("Secundaria")
ws2.append(["SKU", "Nombre"])
ws2.append(["P2-0001", "OPCIONAL 001"])
wb.save("data/demo/codigos_dos_hojas.xlsx")
print("fixtures creados")
PY
```

Luego ejecuta la prueba del core:

```bash
ruby _scripts/dev/prueba_core.rb   # o: rake test
```

Salida esperada: `PRUEBA DEL CORE: CORRECTA` (5 PDFs de 100×50 mm, texto verificado y
caminos negativos: 2 generadas, 2 duplicadas, 1 inválida; además selección de hoja y
omisión de filas vacías).
