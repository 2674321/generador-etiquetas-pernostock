require 'prawn'
require 'roo-xls'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/prawn_outputter'
require 'tty-progressbar'

EXCEL_FILE = 'C:\\RUTA_AL_EXCEL\\maestra_codigos.xlsx'
OUTPUT_DIRECTORY = 'C:\\RUTA_DE_SALIDA\\boletas\\'

def open_excel(file_path)
  Roo::Excelx.new(file_path)
rescue StandardError => e
  handle_error("Error al abrir el archivo Excel: #{e.message}")
end

def create_output_directory(directory_path)
  Dir.mkdir(directory_path) unless Dir.exist?(directory_path)
rescue StandardError => e
  handle_error("Error al crear el directorio de salida: #{e.message}")
end

def generate_barcode_with_text(variable_1, variable_2, progress)
  codigo_text = "Código: #{variable_1}"

  barcode = Barby::Code128B.new(variable_1)
  output_file_pdf = "#{OUTPUT_DIRECTORY}codigo_barras_unico.pdf"

  pdf_width = 10 * 28.35
  pdf_height = 5 * 28.35

  Prawn::Document.generate(output_file_pdf, page_layout: :portrait, page_size: [pdf_width, pdf_height]) do |pdf|
    pdf.font_size 6

    pdf.text_box(codigo_text, at: [5, pdf_height - 20], width: pdf_width - 20, height: pdf_height - 50, align: :left, valign: :center)
    pdf.text_box(variable_2.join(' '), at: [5, pdf_height - 40], width: pdf_width - 20, height: pdf_height - 50, align: :left, valign: :center)
    pdf.font_size 6

    barcode.annotate_pdf(pdf, x: 0, y: pdf_height - 150, xdim: 4, height: 2 * 28.35, align: :left, valign: :center)
  end

  progress.advance(1)
  puts "Boleta generada."
rescue StandardError => e
  handle_error("Error al generar la boleta: #{e.message}")
end

def handle_error(message)
  puts message
  exit
end

begin
  xlsx = open_excel(EXCEL_FILE)
  create_output_directory(OUTPUT_DIRECTORY)

  progress = TTY::ProgressBar.new("Generando boletas [:bar]")

  puts 'Ingrese el código a buscar:'
  search_term = gets.chomp

  xlsx.each do |row|
    variable_1, *variable_2 = row.map(&:to_s)

    if variable_1.downcase.include?(search_term.downcase)
      generate_barcode_with_text(variable_1, variable_2, progress)
      break
    end
  end
rescue StandardError => e
  handle_error("Ha ocurrido un error inesperado: #{e.message}")
end
