# frozen_string_literal: true

require 'gtk3'

require_relative '../generador_etiquetas'
require_relative 'panel_etiqueta'
require_relative 'panel_hoja'

module GeneradorEtiquetas
  # Ventana principal con panel de resultados (lista + vista previa).
  class Aplicacion
    ETIQUETAS_ESTADO = {
      generada: 'PDF',
      lote: 'LOTE',
      duplicada: 'OMIT.',
      invalida: 'INVÁL.',
      error: 'ERROR'
    }.freeze

    # Texto del desplegable de hoja mientras no se ha elegido archivo.
    HOJA_PLACEHOLDER = '(1ª hoja)'.freeze

    def self.correr
      Gtk.init
      app = new
      app.ventana.signal_connect('destroy') { Gtk.main_quit }
      app.ventana.show_all
      Gtk.main
    end

    attr_reader :ventana

    def initialize
      @resultados = []
      construir_ui
      conectar_senales
    end

    private

    def construir_ui
      @ventana = Gtk::Window.new
      @ventana.set_title('Generador de Etiquetas Pernostock')
      @ventana.set_default_size(980, 640)
      @ventana.border_width = 10

      caja_principal = Gtk::Box.new(:vertical, 8)
      caja_principal.pack_start(construir_barra_archivo, expand: false)
      caja_principal.pack_start(construir_barra_opciones, expand: false)

      paned = Gtk::Paned.new(:horizontal)
      paned.pack1(construir_panel_lista, resize: true, shrink: false)
      paned.pack2(construir_panel_previa, resize: true, shrink: false)
      paned.position = 560
      caja_principal.pack_start(paned, expand: true)

      @barra_estado = Gtk::Label.new('Listo. Selecciona un archivo y pulsa Generar.')
      @barra_estado.xalign = 0.0
      @barra_progreso = Gtk::ProgressBar.new
      @barra_progreso.no_show_all = true
      caja_principal.pack_start(@barra_progreso, expand: false)
      caja_principal.pack_start(@barra_estado, expand: false)

      ventana.add(caja_principal)
    end

    def construir_barra_archivo
      barra = Gtk::Box.new(:horizontal, 6)

      @selector_archivo = Gtk::FileChooserButton.new('Abrir hoja de cálculo…', Gtk::FileChooserAction::OPEN)

      @entrada_salida = Gtk::Entry.new
      @entrada_salida.text = File.join(Dir.pwd, 'salida')
      @entrada_salida.hexpand = true
      @entrada_salida.placeholder_text = 'Directorio de salida (por defecto: ./salida)'

      @boton_generar = Gtk::Button.new(label: 'Generar etiquetas')

      barra.pack_start(@selector_archivo, expand: false)
      barra.pack_start(@entrada_salida, expand: true)
      barra.pack_start(@boton_generar, expand: false)
      barra
    end

    def construir_barra_opciones
      barra = Gtk::Box.new(:horizontal, 6)

      @campo_filtrar = Gtk::Entry.new
      @campo_filtrar.placeholder_text = 'Filtrar códigos (contiene)…'
      @campo_filtrar.width_chars = 18

      ajuste = Gtk::Adjustment.new(0, 0, 10_000, 1, 10, 0)
      @campo_cantidad = Gtk::SpinButton.new(ajuste, 1, 0)
      @campo_cantidad.value = 0
      @campo_cantidad.tooltip_text = '0 = sin límite'

      @caso_todas = Gtk::CheckButton.new('Incluir duplicados')
      @caso_todas.tooltip_text = 'Procesa cada fila aunque el código ya esté generado'

      @caso_lote = Gtk::CheckButton.new('Lote A4')
      @caso_lote.tooltip_text = 'Además genera lote_A4.pdf con las etiquetas en cuadrícula'

      ajuste_ancho = Gtk::Adjustment.new(Dimensiones::ANCHO_POR_DEFECTO_MM, 10, 300, 1, 5, 0)
      @campo_ancho = Gtk::SpinButton.new(ajuste_ancho, 1, 1)
      ajuste_alto = Gtk::Adjustment.new(Dimensiones::ALTO_POR_DEFECTO_MM, 10, 300, 1, 5, 0)
      @campo_alto = Gtk::SpinButton.new(ajuste_alto, 1, 1)

      @contenedor_hojas = Gtk::Box.new(:horizontal, 4)
      @contenedor_hojas.pack_start(Gtk::Label.new('Hoja:'), expand: false)
      refrescar_hojas

      etiqueta_tam = Gtk::Label.new('Tamaño (mm):')

      barra.pack_start(@campo_filtrar, expand: false)
      barra.pack_start(@campo_cantidad, expand: false)
      barra.pack_start(@caso_todas, expand: false)
      barra.pack_start(@caso_lote, expand: false)
      barra.pack_start(@contenedor_hojas, expand: false)
      barra.pack_start(etiqueta_tam, expand: false)
      barra.pack_start(@campo_ancho, expand: false)
      barra.pack_start(@campo_alto, expand: false)
      barra.pack_start(Gtk::Label.new(''), expand: true)
      barra
    end

    # Lista las hojas del archivo seleccionado en el desplegable "Hoja".
    def refrescar_hojas
      @contenedor_hojas.remove(@selector_hoja) if @selector_hoja

      @selector_hoja = Gtk::ComboBoxText.new
      archivo = @selector_archivo.filename
      hojas = if archivo && File.file?(archivo)
                begin
                  Libro.hojas(archivo)
                rescue StandardError
                  []
                end
              else
                []
              end

      if hojas.empty?
        @selector_hoja.append_text(HOJA_PLACEHOLDER)
        @selector_hoja.active = 0
      else
        hojas.each { |nombre| @selector_hoja.append_text(nombre) }
        @selector_hoja.active = 0
      end
      @contenedor_hojas.pack_start(@selector_hoja, expand: false)
      @contenedor_hojas.show_all
    end

    def construir_panel_lista
      @almacen = Gtk::ListStore.new(String, String, String, String)
      @vista = Gtk::TreeView.new(@almacen)

      columnas = [['Estado', 0, 0.10], ['Código', 1, 0.26], ['Descripción', 2, 0.40], ['Archivo / Nota', 3, 0.24]]
      columnas.each do |titulo, indice, _ancho|
        renderer = Gtk::CellRendererText.new
        columna = Gtk::TreeViewColumn.new(titulo, renderer, text: indice)
        columna.resizable = true
        columna.min_width = 70
        columna.expand = true if indice == 2
        @vista.append_column(columna)
      end

      ajuste = Gtk::Adjustment.new(0, 0, 1, 1, 1, 0)
      @vista.headers_visible = true
      @scrolled_lista = Gtk::ScrolledWindow.new(nil, nil)
      @scrolled_lista.add(@vista)
      @scrolled_lista
    end

    def construir_panel_previa
      caja = Gtk::Box.new(:vertical, 6)

      @dibujo = Gtk::DrawingArea.new
      @dibujo.hexpand = true
      @dibujo.vexpand = true

      @dibujo.signal_connect('draw') do |_widget, cr|
        dibujar_previa(cr)
        false
      end

      @info_previa = Gtk::Label.new('Selecciona un elemento de la lista para ver la etiqueta.')
      @info_previa.selectable = true
      @info_previa.xalign = 0.0

      @boton_abrir_pdf = Gtk::Button.new(label: 'Abrir el PDF generado')
      @boton_abrir_pdf.sensitive = false

      caja.pack_start(@dibujo, expand: true)
      caja.pack_start(@info_previa, expand: false)
      caja.pack_start(@boton_abrir_pdf, expand: false)
      caja
    end

    def conectar_senales
      @boton_generar.signal_connect('clicked') { generar }
      @boton_abrir_pdf.signal_connect('clicked') { abrir_pdf_seleccionado }
      @vista.selection.signal_connect('changed') { actualizar_previa }
      @selector_archivo.signal_connect('file-set') { refrescar_hojas }
    end

    # ---- Generación -------------------------------------------------------

    def generar
      archivo = @selector_archivo.filename
      unless archivo && File.file?(archivo)
        aviso('Selecciona una hoja de cálculo (xlsx, xls, xlsm, ods) primero.')
        return
      end

      maquina = Maquina.new(
        salida: @entrada_salida.text.strip.empty? ? File.join(Dir.pwd, 'salida') : @entrada_salida.text,
        ancho_mm: @campo_ancho.value.to_f,
        alto_mm: @campo_alto.value.to_f
      )

      @boton_generar.sensitive = false
      @barra_estado.text = 'Generando…'
      @barra_progreso.show_now
      @barra_progreso.fraction = 0.0

      refrescar_hojas if @selector_hoja.active_text.to_s.include?(HOJA_PLACEHOLDER)

      hoja = @selector_hoja.active
      hoja = 0 if hoja.nil? || hoja.negative?

      Thread.new do
        resultado = begin
          maquina.procesar(
            archivo,
            filtrar: texto_vacio(@campo_filtrar.text),
            cantidad: @campo_cantidad.value.to_i.zero? ? nil : @campo_cantidad.value.to_i,
            permitir_duplicados: @caso_todas.active?,
            hoja: hoja,
            lote: @caso_lote.active?,
            en_progreso: proc do |hechas, total|
              fraccion = total.zero? ? 0.0 : hechas.to_f / total
              GLib::Idle.add { @barra_progreso.fraction = fraccion; false }
            end
          )
        rescue StandardError => e
          e
        end
        GLib::Idle.add { aplicar_resultado(resultado) }
      end
    end

    def aplicar_resultado(resultado)
      @boton_generar.sensitive = true
      @barra_progreso.hide
      if resultado.is_a?(StandardError)
        @barra_estado.text = 'Error'
        aviso("Error al generar:\n#{resultado.message}")
      else
        @resultados = resultado.resultados
        rellenar_lista(resultado)
      end
      false
    end

    def rellenar_lista(reporte)
      @almacen.clear
      @resultados.each do |r|
        iter = @almacen.append
        info = if r.generada?
                 r.archivo
               elsif r.con_error?
                 r.error.to_s
               else
                 ''
               end
        @almacen.set_value(iter, 0, ETIQUETAS_ESTADO[r.estado])
        @almacen.set_value(iter, 1, r.codigo.to_s)
        @almacen.set_value(iter, 2, r.descripcion.to_s)
        @almacen.set_value(iter, 3, info)
      end
      @barra_estado.text = "#{reporte}   ·   Filas: #{reporte.total}"
      actualizar_previa
    end

    # ---- Vista previa ------------------------------------------------------

    def seleccionado
      iter = @vista.selection.selected
      return nil unless iter

      indice = iter.path.indices[0]
      @resultados[indice]
    end

    def actualizar_previa
      @layout_previo = nil
      @hoja_previo = nil
      r = seleccionado
      unless r
        @info_previa.text = 'Selecciona un elemento de la lista para ver la etiqueta.'
        @boton_abrir_pdf.sensitive = false
        @dibujo.queue_draw
        return
      end

      if r.lote?
        @hoja_previo = construir_panel_hoja
        @info_previa.text = "#{r.codigo} — #{r.descripcion}. Vista previa de la primera hoja A4."
        @boton_abrir_pdf.sensitive = true
        @dibujo.queue_draw
        return
      end

      etiqueta = Etiqueta.new(codigo: r.codigo, descripcion: r.descripcion, fila: r.fila)
      if etiqueta.codigo_valido?
        @layout_previo = LayoutEtiqueta.calcular(etiqueta,
                                                 ancho_pt: Dimensiones.pt(@campo_ancho.value.to_f),
                                                 alto_pt: Dimensiones.pt(@campo_alto.value.to_f))
        estado_html = {
          generada: '✓ generado', duplicada: '◇ duplicado omitido',
          invalida: '✗ código inválido', error: '✗ error'
        }.fetch(r.estado)
        @info_previa.text = "#{r.codigo} — #{r.descripcion}   (#{estado_html})"
      else
        @info_previa.text = "#{r.codigo} — código no imprimible (sin vista previa)"
      end

      @boton_abrir_pdf.sensitive = r.generada?
      @dibujo.queue_draw
    end

    def construir_panel_hoja
      etiquetas = @resultados.select(&:generada?).map do |r|
        Etiqueta.new(codigo: r.codigo, descripcion: r.descripcion, fila: r.fila)
      end
      return nil if etiquetas.empty?

      PanelHoja.new(
        etiquetas,
        ancho_etiqueta_pt: Dimensiones.pt(@campo_ancho.value.to_f),
        alto_etiqueta_pt: Dimensiones.pt(@campo_alto.value.to_f)
      )
    end

    def dibujar_previa(cr)
      ancho = @dibujo.allocated_width.to_f
      alto = @dibujo.allocated_height.to_f
      return if ancho <= 1 || alto <= 1

      cr.set_source_rgb(0.24, 0.24, 0.24)
      cr.paint

      if @hoja_previo
        @hoja_previo.dibujar(cr, ancho, alto, fondo: :gris)
      elsif @layout_previo
        PanelEtiqueta.new(@layout_previo).dibujar(cr, ancho, alto, fondo: :blanco)
      else
        cr.select_font_face('Helvetica', Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
        cr.set_font_size(13)
        cr.set_source_rgb(1, 1, 1)
        cr.move_to(20, 30)
        cr.show_text('Sin vista previa')
      end
    end

    def abrir_pdf_seleccionado
      r = seleccionado
      return unless r && (r.generada? || r.lote?) && r.archivo && File.file?(r.archivo)

      Process.spawn('xdg-open', r.archivo, out: File::NULL, err: File::NULL)
    end

    def aviso(mensaje)
      dialogo = Gtk::MessageDialog.new(
        parent: ventana,
        flags: Gtk::DialogFlags::MODAL,
        type: Gtk::MessageType::ERROR,
        buttons: Gtk::ButtonsType::OK,
        message: mensaje
      )
      dialogo.run
      dialogo.destroy
    end

    def texto_vacio(valor)
      return nil if valor.nil? || valor.strip.empty?

      valor.strip
    end
  end
end