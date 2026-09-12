# frozen_string_literal: true

module GeneradorEtiquetas
  # Escritura de una etiqueta a PDF (Prawn).
  # Convierte el Layout (coordenadas top-down) a coordenadas Prawn (bottom-up).
  class PdfEtiqueta
    def self.generar(etiqueta, ruta, ancho_pt:, alto_pt:, escala_descripcion: 1.0)
      Prawn::Document.generate(
        ruta,
        page_layout: :portrait,
        page_size: [ancho_pt, alto_pt],
        margin: 0
      ) do |pdf|
        layout = LayoutEtiqueta.calcular(etiqueta, ancho_pt: ancho_pt, alto_pt: alto_pt)
        dibujador = DibujadorPdf.new(pdf, alto_pagina: alto_pt)
        DibujoEtiqueta.dibujar(dibujador, layout)
      end
      true
    end
  end

  # Implementación del "dibujador" abstracto sobre Prawn.
  class DibujadorPdf
    # Prawn: la coordenada Y de un punto es la distancia desde el borde
    # INFERIOR de la página; un texto_box coloca su caja bajando desde ese
    # punto y los rectángulos se trazan desde su borde superior hacia abajo.
    def initialize(pdf, alto_pagina:)
      @pdf = pdf
      @alto_pagina = alto_pagina
    end

    def fondo_blanco(_ancho, _alto)
      @pdf.fill_color 'FFFFFF'
      @pdf.fill_rectangle [0, @alto_pagina], @alto_pagina, @alto_pagina
      @pdf.fill_color '000000'
    end

    def texto(contenido, x:, y:, tamano:, negrita:, familia:, alto_linea:, ancho:, align: :left)
      fuente = familia == DibujoEtiqueta::FAMILIA_CODIGO ? 'Courier' : 'Helvetica'
      alto = alto_linea
      # y (top-down) es el borde superior de la línea; en Prawn la caja empieza
      # desde @alto_pagina - y y desciende `alto`.
      at_y = @alto_pagina - y
      @pdf.text_box(
        contenido,
        at: [x, at_y],
        width: ancho,
        height: alto,
        overflow: :truncate,
        font: fuente,
        size: tamano,
        style: negrita ? :bold : :normal,
        align: align,
        valign: align == :center ? :center : :top,
        leading: 1
      )
    end

    def rect(x, y, ancho, alto)
      # En Prawn rectangle() [x, y] es el borde SUPERIOR; la altura se extiende
      # hacia abajo. Convertimos la Y top-down.
      @pdf.fill_color '000000'
      @pdf.fill_rectangle([x, @alto_pagina - y], ancho, alto)
    end
  end
end