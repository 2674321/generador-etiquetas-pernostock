# data/demo — Fixtures de prueba (ficticios)

Esta carpeta contiene datos **demo y ficticios** para probar el Generador de Etiquetas
sin usar datos reales de PernoStock Ltda.

> Los archivos `*.xlsx` están excluidos de git (`.gitignore`). Si falta el fixture,
> regenéralo así:

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
