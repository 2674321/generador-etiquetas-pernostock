
require 'gtk3'
require 'prawn'
require 'roo-xls'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/prawn_outputter'
require 'tty-progressbar'

$excel_file = ''
$output_directory = 'C:\\RUTA_DE_SALIDA\\etiquetas'

def open_excel(file_path)
  if File.extname(file_path) == ".xlsx"
    Roo::Excelx.new(file_path)
  elsif File.extname(file_path) == ".xls"
    Roo::Excel.new(file_path)
  else
    raise "Formato de archivo no compatible"
  end
rescue StandardError => e
  puts "Error al abrir el archivo Excel: #{e.message}"
  nil
end

def generate_barcode_with_text(variable_1, variable_2, progress, output_directory)
  begin
    codigo_text = "Código: #{variable_1}"
    barcode = Barby::Code128B.new(variable_1)
    output_file_pdf = "#{$output_directory}codigo_barras_unico.pdf"
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
    puts "Boleta generada en: #{output_file_pdf}"
    return File.exist?(output_file_pdf)
  rescue StandardError => e
    puts "Error al generar la boleta: #{e.message}"
    return false
  end
end

def valid_input?(search_term, excel_file)
  if search_term.nil? || search_term.strip.empty?
    show_popup("Por favor, ingrese un término de búsqueda válido.")
    return false
  elsif excel_file.nil? || excel_file.empty?
    show_popup("No se ha seleccionado un archivo Excel.")
    return false
  elsif !File.exist?(excel_file)
    show_popup("El archivo seleccionado no existe.")
    return false
  end
  return true
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

def on_generate_clicked(widget, search_entry, input_file_chooser, output_file_chooser)
  search_term = search_entry.text
  excel_file = input_file_chooser.filename # Obtiene la ruta del archivo seleccionado
  output_directory = output_file_chooser.filename # Obtiene la carpeta de salida seleccionada

  unless valid_input?(search_term, excel_file)
    return
  end

  begin
    xlsx = open_excel(excel_file)
    if xlsx
      progress = TTY::ProgressBar.new("Generando boletas [:bar]")
      found = false
      xlsx.each do |row|
        variable_1, *variable_2 = row.map(&:to_s)
        if variable_1.downcase.include?(search_term.downcase)
          success = generate_barcode_with_text(variable_1, variable_2, progress, output_directory)
          if success
            found = true
            puts 'PDF creado exitosamente'
            show_popup("¡PDF creado exitosamente!")
          else
            puts 'No se pudo crear el PDF'
          end
          break
        end
      end
      show_popup("El término de búsqueda no se encontró en el archivo Excel.") unless found
    end
  rescue StandardError => e
    puts "Error al generar la boleta: #{e.message}"
    show_popup("Error al generar la boleta: #{e.message}")
  end
end

def on_exit_clicked(widget)
  dialog = Gtk::MessageDialog.new(
    parent: nil,
    flags: Gtk::DialogFlags::MODAL,
    type: Gtk::MessageType::QUESTION,
    buttons: Gtk::ButtonsType::YES_NO,
    message: "¿Estás seguro que deseas salir?"
  )

  dialog.signal_connect('response') do |response_id|
    case response_id
    when Gtk::ResponseType::YES
      Gtk.main_quit
    when Gtk::ResponseType::NO, Gtk::ResponseType::DELETE_EVENT
      dialog.close
    end
  end

  dialog.run
  dialog.destroy
end

window = Gtk::Window.new('Generador de Boletas')
window.set_default_size(400, 200)
window.border_width = 10

vbox = Gtk::Box.new(:vertical, 5)
window.add(vbox)

input_file_chooser = Gtk::FileChooserButton.new('Seleccionar Archivo de Entrada', :open)
output_file_chooser = Gtk::FileChooserButton.new('Seleccionar Carpeta de Salida', :select_folder)

search_entry = Gtk::Entry.new
search_entry.set_placeholder_text('Ingrese el código a buscar')

generate_button = Gtk::Button.new(label: 'Generar Boleta')
generate_button.signal_connect('clicked') do |widget|
  on_generate_clicked(widget, search_entry, input_file_chooser, output_file_chooser)
end

exit_button = Gtk::Button.new(label: 'Salir')
exit_button.signal_connect('clicked') do |widget|
  on_exit_clicked(widget)
end

separator = Gtk::Separator.new(:horizontal)

vbox.pack_start(input_file_chooser, expand: false, fill: false, padding: 0)
vbox.pack_start(output_file_chooser, expand: false, fill: false, padding: 0)
vbox.pack_start(search_entry, expand: false, fill: false, padding: 0)
vbox.pack_start(generate_button, expand: false, fill: false, padding: 0)
vbox.pack_start(separator, expand: false, fill: false, padding: 5)
vbox.pack_start(exit_button, expand: false, fill: false, padding: 0)

window.signal_connect('destroy') { Gtk.main_quit }
window.show_all
Gtk.main