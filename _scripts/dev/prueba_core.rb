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

puts
if FALLOS.empty?
  puts "PRUEBA DEL CORE: CORRECTA"
  exit 0
else
  puts "PRUEBA DEL CORE: #{FALLOS.size} FALLOS"
  exit 1
end