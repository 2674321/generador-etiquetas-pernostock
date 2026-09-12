# frozen_string_literal: true

require 'cairo'

require_relative '../generador_etiquetas'
require_relative 'panel_etiqueta'

module GeneradorEtiquetas
  # Vista previa de una página del lote: dibuja la misma cuadrícula que genera
  # `LoteEtiqueta.generar` (misma grarilla, mismas celdas), de modo que lo que se
  # ve coincide con lo que se imprime. Con `pagina:` se elige la página (0-based).
  class PanelHoja
    attr_reader :paginas, :margen_pt, :hueco_pt

    def initialize(etiquetas, ancho_etiqueta_pt:, alto_etiqueta_pt:,
                   ancho_pagina_pt: LoteEtiqueta::A4_ANCHO_PT,
                   alto_pagina_pt: LoteEtiqueta::A4_ALTO_PT,
                   margen_pt: LoteEtiqueta::MARGEN_PT, hueco_pt: LoteEtiqueta::HUECO_PT,
                   pagina: 0)
      @etiquetas = etiquetas
      @ancho_etiqueta_pt = ancho_etiqueta_pt
      @alto_etiqueta_pt = alto_etiqueta_pt
      @ancho_pagina_pt = ancho_pagina_pt
      @alto_pagina_pt = alto_pagina_pt
      @margen_pt = margen_pt
      @hueco_pt = hueco_pt
      @columnas, @filas, @por_hoja = LoteEtiqueta.grarilla(
        ancho_pagina_pt: ancho_pagina_pt, alto_pagina_pt: alto_pagina_pt,
        ancho_etiqueta_pt: ancho_etiqueta_pt, alto_etiqueta_pt: alto_etiqueta_pt,
        margen_pt: margen_pt, hueco_pt: hueco_pt
      )
      @pagina = pagina
      @paginas = LoteEtiqueta.paginas(etiquetas.size, ancho_pagina_pt: ancho_pagina_pt,
                                       alto_pagina_pt: alto_pagina_pt,
                                       ancho_etiqueta_pt: ancho_etiqueta_pt,
                                       alto_etiqueta_pt: alto_etiqueta_pt,
                                       margen_pt: margen_pt, hueco_pt: hueco_pt)
    end

    # Etiquetas de la página que se está viendo.
    def etiquetas_pagina
      desde = @pagina * @por_hoja
      @etiquetas[desde, @por_hoja] || []
    end

    # Dibuja, centrada y conservando la proporción de la hoja, la primera página.
    def dibujar(cr, ancho_px, alto_px, fondo: :blanco)
      escala = contener(ancho_px, alto_px)
      ofs_x = centrar_x(ancho_px, escala)
      ofs_y = centrar_y(alto_px, escala)

      if fondo == :gris
        cr.set_source_rgb(0.90, 0.90, 0.90)
        cr.rectangle(0, 0, ancho_px, alto_px)
        cr.fill
      end

      cr.save
      cr.translate(ofs_x, ofs_y)
      cr.scale(escala, escala)

      # Fondo de la hoja (blanco) y guías tenues de las celdas.
      cr.set_source_rgb(1, 1, 1)
      cr.rectangle(0, 0, @ancho_pagina_pt, @alto_pagina_pt)
      cr.fill
      cr.set_source_rgb(0.86, 0.86, 0.86)
      pagina_etiquetas = etiquetas_pagina
      pagina_etiquetas.each_with_index do |_e, i|
        x, y = LoteEtiqueta.celda(i, @columnas,
                                  ancho_etiqueta_pt: @ancho_etiqueta_pt,
                                  alto_etiqueta_pt: @alto_etiqueta_pt,
                                  margen_pt: @margen_pt, hueco_pt: @hueco_pt)
        cr.rectangle(x, y, @ancho_etiqueta_pt, @alto_etiqueta_pt)
        cr.stroke
      end

      pagina_etiquetas.each_with_index do |etiqueta, i|
        layout = LayoutEtiqueta.calcular(etiqueta,
                                         ancho_pt: @ancho_etiqueta_pt,
                                         alto_pt: @alto_etiqueta_pt)
        x, y = LoteEtiqueta.celda(i, @columnas,
                                  ancho_etiqueta_pt: @ancho_etiqueta_pt,
                                  alto_etiqueta_pt: @alto_etiqueta_pt,
                                  margen_pt: @margen_pt, hueco_pt: @hueco_pt)
        cr.save
        cr.translate(x, y)
        DibujoEtiqueta.dibujar(DibujadorCairo.new(cr, 1.0), layout)
        cr.restore
      end

      cr.restore
    end

    private

    # Factor para que la página quepa en [ancho_px, alto_px] conservando forma.
    def contener(ancho_px, alto_px)
      [ancho_px / @ancho_pagina_pt, alto_px / @alto_pagina_pt].min
    end

    def centrar_x(ancho_px, escala)
      (ancho_px - (@ancho_pagina_pt * escala)) / 2.0
    end

    def centrar_y(alto_px, escala)
      (alto_px - (@alto_pagina_pt * escala)) / 2.0
    end
  end
end