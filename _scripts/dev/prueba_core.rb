#!/usr/bin/env ruby
# frozen_string_literal: true

# Prueba mínima funcional del CORE del Generador de Etiquetas (sin GUI).
# Lee un `.xlsx` demo con códigos ficticios y genera PDFs Code128 con Prawn.
#
# Uso (dentro de generador-etiquetas-pernostock):
#   mise exec -- ruby _scripts/dev/prueba_core.rb
#
# No usa datos reales de PernoStock. Los códigos demo son ficticios.

require "roo"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/prawn_outputter"
require "prawn"
require "fileutils"

DEMO_XLSX = "data/demo/codigos_demo.xlsx"
OUTPUT_DIR = "tmp/demo_pdfs"

abort "No se encuentra #{DEMO_XLSX}. Genera primero el fixture demo." unless File.exist?(DEMO_XLSX)

FileUtils.mkdir_p(OUTPUT_DIR)

wb = Roo::Spreadsheet.open(DEMO_XLSX)
sheet = wb.sheet(0)
cantidad = 5
codes = (1..cantidad).map { |i| sheet.cell(i, 1).to_s }

puts "Códigos leídos desde el fixture: #{codes.join(', ')}"

codes.each_with_index do |code, idx|
  barcode = Barby::Code128.new(code)
  Prawn::Document.generate("#{OUTPUT_DIR}/etiqueta_#{idx + 1}.pdf", page_layout: :portrait, page_size: [75, 28]) do
    move_down 10
    barcode.annotate_pdf(self, x: 5, y: cursor - 5, height: 20)
  end
end

pdfs = Dir["#{OUTPUT_DIR}/*.pdf"].sort
puts "PDFs generados: #{pdfs.size}"
puts pdfs
