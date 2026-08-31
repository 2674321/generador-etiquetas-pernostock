# frozen_string_literal: true

# Variante CLI (consola) del Generador de Etiquetas.
#
# Acepta el archivo de entrada como argumento y crea la carpeta de salida
# de forma portable (respecto al proyecto / al directorio de trabajo).
#
# Uso:
#   ruby lib/generador_etiquetas_cli.rb <archivo.xlsx> [directorio_salida]
#
# El directorio de salida es opcional; si no se indica, se usa
# 'salida/' dentro del proyecto.

require 'prawn'
require 'roo-xls'
require 'roo'
require 'fileutils'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/prawn_outputter'
require 'tty-progressbar'

PROJECT_ROOT = File.expand_path('..', __dir__)
DEFAULT_OUTPUT_DIR = File.join(PROJECT_ROOT, 'salida')

def resolve_input_path(raw)
  expand = raw.nil? ? nil : File.expand_path(raw)
  unless expand && File.exist?(expand)
    raise "Archivo no encontrado:\n#{expand || '(sin archivo)'}"
  end
  ext = File.extname(expand).downcase
  unless ['.xlsx', '.xls'].include?(ext)
    raise "Se esperaba un archivo XLS/XLSX. Recibido: #{ext.empty? ? '(sin extensión)' : ext}"
  end
  expand
rescue => e
  handle_error(e.message)
end

def resolve_output_path(raw)
  expand = raw.nil? ? DEFAULT_OUTPUT_DIR : File.expand_path(raw)
  FileUtils.mkdir_p(expand)
  expand
rescue => e
  handle_error("Error al crear el directorio de salida: #{e.message}")
end

def open_excel(file_path)
  Roo::Spreadsheet.open(file_path)
rescue => e
  handle_error("No se pudo leer el archivo: #{e.message}")
end

def build_barcode_pdf(variable_1, variable_2, output_directory)
  codigo_text = "Código: #{variable_1}"
  barcode = Barby::Code128B.new(variable_1)
  output_file_pdf = File.join(output_directory, 'codigo_barras_unico.pdf')

  pdf_width = 10 * 28.35
  pdf_height = 5 * 28.35

  Prawn::Document.generate(output_file_pdf, page_layout: :portrait, page_size: [pdf_width, pdf_height]) do |pdf|
    pdf.font_size 6
    pdf.text_box(codigo_text, at: [5, pdf_height - 20], width: pdf_width - 20, height: pdf_height - 50, align: :left, valign: :center)
    pdf.text_box(variable_2.join(' '), at: [5, pdf_height - 40], width: pdf_width - 20, height: pdf_height - 50, align: :left, valign: :center)
    pdf.font_size 6
    barcode.annotate_pdf(pdf, x: 0, y: pdf_height - 150, xdim: 4, height: 2 * 28.35, align: :left, valign: :center)
  end

  output_file_pdf
end

def sanitize(value)
  value.to_s.scrub('')
end

def handle_error(message)
  warn message
  exit 1
end

def usage
  <<~TEXT
    Uso:
      ruby lib/generador_etiquetas_cli.rb <archivo.xlsx> [directorio_salida]

    Ejemplos:
      ruby lib/generador_etiquetas_cli.rb data/demo/codigos_demo.xlsx
      ruby lib/generador_etiquetas_cli.rb ruta/absoluta/archivo.xlsx tmp/salida
  TEXT
end

input_arg = ARGV[0]
if input_arg.nil? || input_arg.strip.empty?
  warn usage
  exit 1
end

excel_file = resolve_input_path(input_arg)
output_directory = resolve_output_path(ARGV[1])

xlsx = open_excel(excel_file)
worksheet = xlsx.sheet(0)

progress = TTY::ProgressBar.new("Generando boletas [:bar]")

puts 'Ingrese el código a buscar:'
search_term = STDIN.gets.chomp
term = sanitize(search_term).strip.downcase

found = false
(worksheet.first_row..worksheet.last_row).each do |row_index|
  variable_1 = sanitize(worksheet.cell(row_index, 1)).to_s.strip
  variable_2 = worksheet.row(row_index)[1..-1].to_a
  next unless variable_1.downcase.include?(term)

  output_file_pdf = build_barcode_pdf(variable_1, variable_2, output_directory)
  progress.advance(1)
  puts "Boleta generada en: #{output_file_pdf}"
  found = true
  break
end
puts 'Boleta no encontrada para el término indicado.' unless found
