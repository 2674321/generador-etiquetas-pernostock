require 'gtk3'
require 'roo'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/prawn_outputter'
require 'prawn'
require 'fileutils'

module MessageHelper
  def self.show_message(message)
    puts message
    dialog = Gtk::MessageDialog.new(
      parent: nil,
      flags: Gtk::DialogFlags::DESTROY_WITH_PARENT,
      type: Gtk::MessageType::INFO,
      buttons: Gtk::ButtonsType::OK,
      message: message
    )
    dialog.run
    dialog.destroy
  end
end

class VentanaGTK
  def initialize
    @ventana = Gtk::Window.new
    configurar_ventana
    construir_interfaz
    @expander2_usado = false
    @ventana.show_all
  end

  private

  def configurar_ventana
    @ventana.set_title("Programa de etiquetas")
    @ventana.set_default_size(600, 400)
    @ventana.signal_connect("destroy") { Gtk.main_quit }
  end

  def construir_interfaz
    contenedor_principal = Gtk::Box.new(:vertical, 10)
    contenedor_principal.margin = 20
    contenedor_principal.add(titulo)
    contenedor_principal.add(filechooser_principal)
    contenedor_principal.add(expander2)
    contenedor_principal.add(botones_row)
    @ventana.add(contenedor_principal)
  end

  def titulo
    titulo = Gtk::Label.new("Generador de etiquetas")
    titulo.set_halign(Gtk::Align::START)
    titulo.set_margin_bottom(10)
    titulo
  end

  def filechooser_principal
    vbox = Gtk::Box.new(:vertical, 5)
    label = Gtk::Label.new("Archivo a leer")
    vbox.add(label)
    filechooser = Gtk::FileChooserButton.new("Seleccionar archivo", Gtk::FileChooserAction::OPEN)
    filechooser.set_margin_bottom(10)
    vbox.add(filechooser)
    @filechooser_principal = filechooser
    vbox
  end

  def expander2
    expander2 = Gtk::Expander.new("Cantidad de Etiquetas")
    expander2.set_margin_bottom(5)
    contenido_expander2 = Gtk::Box.new(:vertical, 5)
    contenido_expander2.margin_start = 20
    contenido_expander2.margin_top = 5
    @entry_expander2 = Gtk::Entry.new
    @entry_expander2.set_placeholder_text("Ingrese Cantidad de Etiquetas")
    @entry_expander2.set_margin_bottom(10)
    @entry_expander2.signal_connect("changed") { @expander2_usado = !@entry_expander2.text.strip.empty? }
    contenido_expander2.add(@entry_expander2)
    expander2.add(contenido_expander2)
    expander2
  end

  def botones_row
    botones_row = Gtk::Box.new(:horizontal, 5)
    botones_row.margin_top = 10
    boton_cerrar = Gtk::Button.new(label: "Cerrar")
    boton_cerrar.signal_connect("clicked") { cerrar_ventana }
    boton_crear_etiquetas = Gtk::Button.new(label: "Crear Etiquetas")
    boton_crear_etiquetas.signal_connect("clicked") { crear_etiquetas }
    botones_row.add(boton_cerrar)
    botones_row.add(boton_crear_etiquetas)
    botones_row
  end

  def cerrar_ventana
    Gtk.main_quit
  end

  def crear_etiquetas
    if !@expander2_usado
      MessageHelper.show_message("Por favor selecciona un archivo o ingresa la cantidad de etiquetas.")
    else
      generate_barcodes_and_pdfs
      MessageHelper.show_message("Códigos de barras generados y PDFs creados.")
    end
  end

  def generate_barcodes_and_pdfs
    begin
      filename = @filechooser_principal.filename
      workbook = Roo::Spreadsheet.open(filename)
      sheet = workbook.sheet(0)
      cantidad_etiquetas = @entry_expander2.text.strip.to_i

      # Creamos un directorio para guardar los PDFs
      FileUtils.mkdir_p('pdfs')

      cantidad_etiquetas.times do |i|
        code = sheet.cell(i + 1, 1) # Suponiendo que los códigos están en la primera columna de la hoja de cálculo
        barcode = Barby::Code128.new(code)

        # Creamos el PDF
        Prawn::Document.generate("pdfs/etiqueta_#{i + 1}.pdf", page_layout: :portrait, page_size: [75, 28]) do
          move_down 10
          barcode.annotate_pdf(self, x: 5, y: cursor - 5, height: 20)
        end
      end

      MessageHelper.show_message("Códigos de barras generados y PDFs creados en la carpeta 'pdfs'.")
    rescue => e
      MessageHelper.show_message("Error al generar los códigos de barras y PDFs: #{e.message}")
    end
  end


end

Gtk.init
VentanaGTK.new
Gtk.main
