# frozen_string_literal: true

module GeneradorEtiquetas
  # Escritura de una etiqueta a PDF (Prawn).
  # Convierte el Layout (coordenadas top-down) a coordenadas Prawn (bottom-up).
  class PdfEtiqueta
    def self.generar(etiqueta, ruta, ancho_pt:, alto_pt:, escala_descripcion: 1.0,
                   tipo_codigo: LayoutEtiqueta::TIPO_CODE128)
      Prawn::Document.generate(
        ruta,
        page_layout: :portrait,
        page_size: [ancho_pt, alto_pt],
        margin: 0,
        info: {
          Title: "Etiqueta #{etiqueta.codigo}",
          Subject: etiqueta.descripcion,
          Author: 'PernoLabel',
          Creator: 'Prawn'
        }
      ) do |pdf|
        layout = LayoutEtiqueta.calcular(etiqueta, ancho_pt: ancho_pt, alto_pt: alto_pt,
                                         tipo_codigo: tipo_codigo)
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
    #
    # origen_x/origen_y permiten dibujar la etiqueta en una posición
    # cualquiera de la página (usado por el lote A4): son el desplazamiento
    # en coordenadas top-down de la esquina superior izquierda de la etiqueta.
    def initialize(pdf, alto_pagina:, origen_x: 0.0, origen_y: 0.0)
      @pdf = pdf
      @alto_pagina = alto_pagina
      @origen_x = origen_x.to_f
      @origen_y = origen_y.to_f
    end

    # Y absoluta (top-down) → coordenada de Prawn en el fondo de la hoja.
    def abajo(y_top_down)
      @alto_pagina - y_top_down
    end

    def fondo_blanco(ancho, alto)
      @pdf.fill_color 'FFFFFF'
      @pdf.fill_rectangle [@origen_x, abajo(@origen_y + alto)], ancho, alto
      @pdf.fill_color '000000'
    end

    def texto(contenido, x:, y:, tamano:, negrita:, familia:, alto_linea:, ancho:, align: :left)
      fuente = familia == DibujoEtiqueta::FAMILIA_CODIGO ? 'Courier' : 'Helvetica'
      alto = alto_linea
      # y (top-down) es el borde superior de la línea; en Prawn la caja empieza
      # desde ese punto (en el fondo de la hoja) y desciende `alto`.
      at_y = abajo(@origen_y + y)
      @pdf.text_box(
        contenido,
        at: [@origen_x + x, at_y],
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
      @pdf.fill_rectangle([@origen_x + x, abajo(@origen_y + y)], ancho, alto)
    end
  end
end