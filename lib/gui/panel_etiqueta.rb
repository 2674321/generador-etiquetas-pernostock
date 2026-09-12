# frozen_string_literal: true

require 'cairo'

require_relative '../generador_etiquetas'

module GeneradorEtiquetas
  # Implementación del "dibujador" abstracto sobre Cairo (vista previa).
  # Cairo usa coordenadas top-down por defecto: coincide con el Layout.
  class DibujadorCairo
    # `escala` convierte pt → px del contexto.
    def initialize(cr, escala)
      @cr = cr
      @escala = escala
    end

    def fondo_blanco(ancho, alto)
      @cr.set_source_rgb(1, 1, 1)
      @cr.rectangle(0, 0, ancho * @escala, alto * @escala)
      @cr.fill
    end

    def texto(contenido, x:, y:, tamano:, negrita:, familia:, alto_linea:, ancho:, align: :left)
      peso = negrita ? Cairo::FONT_WEIGHT_BOLD : Cairo::FONT_WEIGHT_NORMAL
      @cr.select_font_face(familia, Cairo::FONT_SLANT_NORMAL, peso)
      @cr.set_font_size(tamano * @escala)
      ext = @cr.text_extents(contenido)

      origen_x = case align
                 when :center then x + ((ancho - ext.width) / 2.0)
                 when :right  then x + (ancho - ext.width)
                 else x
                 end
      origen_y = y + (tamano * 0.8)

      @cr.set_source_rgb(0, 0, 0)
      @cr.move_to(origen_x * @escala, origen_y * @escala)
      @cr.show_text(contenido)
    end

    def rect(x, y, ancho, alto)
      @cr.set_source_rgb(0, 0, 0)
      @cr.rectangle(x * @escala, y * @escala, ancho * @escala, alto * @escala)
      @cr.fill
    end
  end

  # Dibuja un Layout de etiqueta en un contexto Cairo, centrado y con la
  # proporción de la etiqueta conservada.
  class PanelEtiqueta
    def initialize(layout)
      @layout = layout
    end

    def dibujar(cr, ancho_px, alto_px, fondo: :blanco)
      escala = [ancho_px / @layout.pagina_ancho, alto_px / @layout.pagina_alto].min

      if fondo == :gris
        cr.set_source_rgb(0.90, 0.90, 0.90)
        cr.paint
      end

      ofs_x = (ancho_px - (@layout.pagina_ancho * escala)) / 2.0
      ofs_y = (alto_px - (@layout.pagina_alto * escala)) / 2.0

      cr.save
      cr.translate(ofs_x.to_f, ofs_y.to_f)
      cr.scale(escala, escala)
      DibujoEtiqueta.dibujar(DibujadorCairo.new(cr, 1.0), @layout)
      cr.restore
    end
  end
end