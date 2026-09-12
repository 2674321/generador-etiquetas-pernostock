#!/usr/bin/env ruby
# frozen_string_literal: true

# Prueba mínima funcional del CORE del Generador de Etiquetas (sin GUI).
# - Genera PDFs Code128 (100×50 mm) desde los fixtures demo.
# - Verifica que el PDF es 283.46×141.73 pt y contiene barras y texto.
# - Ejerce caminos negativos: encabezado, duplicados y código no imprimible.
#
# Uso (dentro de generador-etiquetas-pernostock):
#   ruby _scripts/dev/prueba_core.rb
#
# No usa datos reales de PernoStock. Los códigos demo son ficticios.

require "fileutils"
require_relative "../../lib/generador_etiquetas"

DEMO = "data/demo/codigos_demo.xlsx"
PROBLEMAS = "data/demo/codigos_con_problemas.xlsx"
DOS_HOJAS = "data/demo/codigos_dos_hojas.xlsx"
DEMO_CSV = "data/demo/codigos_demo.csv"
SALIDA = "tmp/demo_pdfs/core_prueba"
ANCHO_PT = GeneradorEtiquetas::Dimensiones.pt(100)
ALTO_PT = GeneradorEtiquetas::Dimensiones.pt(50)
MEDIA_BOX = %r{/MediaBox \[\d+ \d+ ([0-9.]+) ([0-9.]+)\]}m

FALLOS = []
def comprobar(condicion, mensaje)
  if condicion
    puts "  OK  #{mensaje}"
  else
    puts "  FALLO #{mensaje}"
    FALLOS << mensaje
  end
end

def tamano_media_box(pdf)
  m = MEDIA_BOX.match(File.binread(pdf))
  m && [m[1].to_f, m[2].to_f]
end

abort "No se encuentra #{DEMO}." unless File.exist?(DEMO)

FileUtils.rm_rf(SALIDA)
FileUtils.mkdir_p(SALIDA)

puts "== Generación desde fixture demo =="
maquina = GeneradorEtiquetas::Maquina.new(salida: SALIDA)
reporte = maquina.procesar(DEMO)
comprobar(reporte.generadas == 5, "se generan 5 etiquetas (== #{reporte.generadas})")
comprobar(reporte.errores.zero?, "0 errores")

puts "== Estructura de los PDF =="
pdfs = Dir["#{SALIDA}/*.pdf"].sort
pdfs.each do |pdf|
  tamano = tamano_media_box(pdf)
  ajustado = tamano &&
             (tamano[0] - ANCHO_PT).abs < 0.05 &&
             (tamano[1] - ALTO_PT).abs < 0.05
  comprobar(ajustado,
            "#{File.basename(pdf)} es 100×50 mm (#{tamano && tamano.map { |v| v.round(2) }.join(' × ')})")
end
comprobar(pdfs.size == 5, "5 archivos en #{SALIDA}")

puts "== Si hay pdftotext, se comprueba contenido textual =="
if system("which", "pdftotext", out: File::NULL, err: File::NULL)
  texto = `pdftotext -layout #{File.join(SALIDA, 'PET-1001.pdf')} -`
  comprobar(texto.include?("BATERIA DEMO 001"), "el texto incluye la descripción")
  comprobar(texto.include?("PET-1001"), "el texto incluye el código legible")
else
  puts "  (pdftotext no disponible; se omite esta comprobación)"
end

puts "== Si hay pdfinfo, se comprueban los metadatos =="
if system("which", "pdfinfo", out: File::NULL, err: File::NULL)
  meta = `pdfinfo #{File.join(SALIDA, 'PET-1001.pdf')}`
  comprobar(meta.include?("Title:           Etiqueta PET-1001"), "Title en metadatos")
  comprobar(meta.include?("BATERIA DEMO 001"), "Subject (descripción) en metadatos")
  comprobar(meta.include?("Author:") && meta.include?("PernoLabel"),
            "Author con la identidad PernoLabel")
else
  puts "  (pdfinfo no disponible; se omite esta comprobación)"
end

puts "== Lote A4 (cuadrícula) =="
rime = maquina.procesar(DEMO, lote: true)
comprobar(rime.lotes == 1, "el reporte incluye 1 lote (== #{rime.lotes})")
ruta_lote = File.join(SALIDA, GeneradorEtiquetas::LoteEtiqueta::NOMBRE_ARCHIVO)
comprobar(File.file?(ruta_lote), "se crea #{GeneradorEtiquetas::LoteEtiqueta::NOMBRE_ARCHIVO}")
if File.exist?(ruta_lote)
  binario = File.binread(ruta_lote)
  dimensiones_lote = codigo_dupla = nil
  m = %r{/MediaBox \[\d+ \d+ ([0-9.]+) ([0-9.]+)\]}.match(binario)
  dimensiones_lote = m && [m[1].to_f.round(2), m[2].to_f.round(2)]
  comprobar(dimensiones_lote == [595.28, 841.89], "lote es A4 (== #{dimensiones_lote.inspect})")
  if system("which", "pdftotext", out: File::NULL, err: File::NULL)
    texto = `pdftotext -layout #{ruta_lote} -`
    codigo_dupla = %w[PET-1001 PET-1002 PET-1003 PET-1004 PET-1005].all? { |c| texto.include?(c) }
    comprobar(codigo_dupla, "la hoja A4 contiene los 5 códigos")
  end

  maquina.procesar(DEMO, lote: true, lote_margen_pt: GeneradorEtiquetas::Dimensiones.pt(10),
                   lote_hueco_pt: GeneradorEtiquetas::Dimensiones.pt(3))
  comprobar(File.file?(ruta_lote), "lote con margen/hueco a medida (10 y 3 mm) se regenera")
end

puts "== Callback de progreso =="
avances = []
maquina.procesar(DEMO, en_progreso: ->(hechas, total) { avances << [hechas, total] })
comprobar(avances.last == [5, 5], "se avisa de 5/5 (== #{avances.last.inspect})")

puts "== Tipos de código: QR y ambos =="
qr_dir = "#{SALIDA}/qr"
FileUtils.mkdir_p(qr_dir)
qr = GeneradorEtiquetas::Maquina.new(salida: qr_dir)
r_qr = qr.procesar(DEMO, cantidad: 1, tipo_codigo: :qr)
comprobar(r_qr.generadas == 1, "QR → 1 generada (== #{r_qr.generadas})")
r_ambos = qr.procesar(DEMO, cantidad: 1, tipo_codigo: "ambos")
comprobar(r_ambos.generadas == 1, "ambos → 1 generada (== #{r_ambos.generadas})")
tipo_cuadre = begin
  GeneradorEtiquetas::LayoutEtiqueta.normalizar_tipo("barras")
  GeneradorEtiquetas::LayoutEtiqueta.normalizar_tipo(:holograma)
  false
rescue ArgumentError
  true
end
comprobar(tipo_cuadre, "tipo inválido lanza ArgumentError")

if system("which", "pdftoppm", out: File::NULL, err: File::NULL)
  qr_png = "#{qr_dir}/PET-1001"
system("pdftoppm", "-r", "72", "-singlefile", "-png", "-gray",
       File.join(qr_dir, "PET-1001.pdf"), qr_png)
  qr_png = "#{qr_png}.png"
  if system("which", "identify", out: File::NULL, err: File::NULL) && File.exist?(qr_png)
    info = `identify -format "%[fx:mean]" #{qr_png}`.to_f
    comprobar(info.between?(0.05, 0.95), "QR renderiza contraste (#{info.round(3)})")
  else
    puts "  (no hay identify; se omite el chequeo de píxeles del QR)"
  end
end

if File.exist?(PROBLEMAS)
  puts "== Caminos negativos (fixture con problemas) =="
  r2 = maquina.procesar(PROBLEMAS)
  comprobar(r2.generadas == 2, "2 generadas (== #{r2.generadas})")
  comprobar(r2.duplicadas == 2, "2 duplicadas omitidas (== #{r2.duplicadas})")
  comprobar(r2.invalidas == 1, "1 inválida omitida (== #{r2.invalidas})")
  comprobar(r2.errores.zero?, "0 errores")
else
  puts "  (no existe #{PROBLEMAS}; se omite)"
end

if File.exist?(DOS_HOJAS)
  puts "== Selección de hoja y filas vacías =="
  comprobar(GeneradorEtiquetas::Libro.hojas(DOS_HOJAS) == %w[Principal Secundaria],
            "libro.hojas devuelve %w[Principal Secundaria]")
  r3 = maquina.procesar(DOS_HOJAS, hoja: "Secundaria")
  comprobar(r3.generadas == 1, "hoja 'Secundaria' → 1 generada (== #{r3.generadas})")
  r4 = maquina.procesar(DOS_HOJAS, hoja: 0)
  comprobar(r4.total == 2, "hoja Principal omite la fila vacía (2 filas, == #{r4.total})")
  hola = begin
           maquina.procesar(DOS_HOJAS, hoja: "NoExiste")
           false
         rescue ArgumentError
           true
         end
  comprobar(hola, "hoja inexistente lanza ArgumentError")
else
  puts "  (no existe #{DOS_HOJAS}; se omite)"
end

puts "== CSV (mismo contenido que el fixture con problemas) =="
if File.exist?(DEMO_CSV)
  csv = maquina.procesar(DEMO_CSV)
  comprobar(csv.generadas == 2, "CSV → 2 generadas (== #{csv.generadas})")
  comprobar(csv.duplicadas == 2, "CSV → 2 duplicadas omitidas (== #{csv.duplicadas})")
  comprobar(csv.invalidas == 1, "CSV → 1 inválida omitida (== #{csv.invalidas})")
else
  puts "  (no existe #{DEMO_CSV}; se omite)"
end

puts
if FALLOS.empty?
  puts "PRUEBA DEL CORE: CORRECTA"
  exit 0
else
  puts "PRUEBA DEL CORE: #{FALLOS.size} FALLOS"
  exit 1
end