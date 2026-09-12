require 'tty-progressbar'
require 'gtk3'
require 'prawn'
require 'roo-xls'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/prawn_outputter'

def open_excel(file_path)
  case File.extname(file_path)
  when ".xlsx"
    Roo::Excelx.new(file_path)
  when ".xls"
    Roo::Excel.new(file_path)
  else
    raise "Formato de archivo no compatible"
  end
rescue StandardError => e
  puts "Error al abrir el archivo Excel: #{e.message}"
  nil
end

def show_success_popup(output_file_pdf)
  dialog = Gtk::MessageDialog.new(
    parent: nil,
    flags: Gtk::DialogFlags::MODAL,
    type: Gtk::MessageType::INFO,
    buttons: Gtk::ButtonsType::OK,
    message: "El PDF se ha generado correctamente en:\n#{output_file_pdf}"
  )
  dialog.run
  dialog.destroy
end

def process_excel_file(search_term, excel_file, output_directory)
  xlsx = open_excel(excel_file)
  return unless xlsx

  progress = TTY::ProgressBar.new("Generando etiquetas [:bar]")
  found = false

  xlsx.each do |row|
    variable_1, *variable_2 = row.map(&:to_s)
    if variable_1.downcase.include?(search_term.downcase)
      success = generate_label_pdf(variable_1, variable_2, progress, output_directory, search_term)
      found = true if success
      break
    end
  end

  show_popup("El término de búsqueda no se encontró en el archivo Excel.") unless found
end

def valid_input?(search_term, excel_file)
  if search_term.nil? || search_term.strip.empty?
    show_popup("Por favor, ingrese un término de búsqueda válido.")
    return false
  elsif excel_file.nil? || excel_file.empty? || !File.exist?(excel_file)
    show_popup("Seleccione un archivo Excel válido.")
    return false
  end

  true
end

def show_popup(message)
  dialog = Gtk::MessageDialog.new(
    parent: nil,
    flags: Gtk::DialogFlags::MODAL,
    type: Gtk::MessageType::INFO,
    buttons: Gtk::ButtonsType::OK,
    message: message
  )
  dialog.run
  dialog.destroy
end

def generate_label_pdf(variable_1, variable_2, progress, output_directory, search_term)
  codigo_text = "Código: #{variable_1}"
  barcode = Barby::Code128B.new(variable_1)
  output_file_pdf = "#{output_directory}/codigo_barras_unico.pdf"
  pdf_width = 10 * 28.35
  pdf_height = 5 * 28.35

  Prawn::Document.generate(output_file_pdf, page_layout: :portrait, page_size: [pdf_width, pdf_height]) do |pdf|
    pdf.font_size 6
    pdf.text_box(codigo_text, at: [5, pdf_height - 20], width: pdf_width - 20, height: pdf_height - 50, align: :left, valign: :center)
    pdf.text_box(variable_2.join(' '), at: [5, pdf_height - 40], width: pdf_width - 20, height: pdf_height - 50, align: :left, valign: :center)
    pdf.font_size 6
    barcode.annotate_pdf(pdf, x: 0, y: pdf_height - 150, xdim: 2, height: 2 * 28.35, align: :left, valign: :center)
  end

  progress.advance(1)
  output_message = "Etiqueta generada en: #{output_file_pdf}"
  puts output_message
  show_success_popup(output_file_pdf) if File.exist?(output_file_pdf)
  File.exist?(output_file_pdf)
rescue StandardError => e
  puts "Error al generar la etiqueta para '#{search_term}': #{e.message}"
  false
end

def on_generate_clicked(widget, search_entry, input_file_chooser, output_file_chooser)
  search_term = search_entry.text
  excel_file = input_file_chooser.filename
  output_directory = output_file_chooser.filename

  return unless valid_input?(search_term, excel_file)

  begin
    process_excel_file(search_term, excel_file, output_directory)
  rescue StandardError => e
    puts "Error al generar la etiqueta: #{e.message}"
    show_popup("Error al generar la etiqueta: #{e.message}")
  end
end

def confirm_exit
  dialog = Gtk::MessageDialog.new(
    parent: nil,
    flags: Gtk::DialogFlags::MODAL,
    type: Gtk::MessageType::QUESTION,
    buttons: Gtk::ButtonsType::YES_NO,
    message: "¿Estás seguro que deseas salir?"
  )

  response = dialog.run
  dialog.destroy

  Gtk.main_quit if response == Gtk::ResponseType::YES
end

def setup_gui
  window = Gtk::Window.new('Generador de Etiquetas')
  window.set_default_size(400, 200)
  window.border_width = 10

  vbox = Gtk::Box.new(:vertical, 5)
  window.add(vbox)

  input_file_chooser = Gtk::FileChooserButton.new('Seleccionar Archivo de Entrada', :open)
  output_file_chooser = Gtk::FileChooserButton.new('Seleccionar Carpeta de Salida', :select_folder)

  search_entry = Gtk::Entry.new
  search_entry.set_placeholder_text('Ingrese el código a buscar')

  generate_button = Gtk::Button.new(label: 'Generar Etiqueta')
  generate_button.signal_connect('clicked') do |widget|
    on_generate_clicked(widget, search_entry, input_file_chooser, output_file_chooser)
  end

  exit_button = Gtk::Button.new(label: 'Salir')
  exit_button.signal_connect('clicked') { confirm_exit }

  separator_generate_exit = Gtk::Separator.new(:horizontal)

  [input_file_chooser, output_file_chooser, search_entry, generate_button, separator_generate_exit, exit_button].each do |element|
    vbox.pack_start(element, expand: false, fill: false, padding: 0)
  end

  window.signal_connect('destroy') { confirm_exit }
  window.show_all
  Gtk.main
end

setup_gui