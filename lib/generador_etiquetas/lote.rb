# frozen_string_literal: true

module GeneradorEtiquetas
  # Hoja imprimible con una cuadrícula de etiquetas iguales (lote A4).
  # Reutiliza LayoutEtiqueta + DibujoEtiqueta + DibujadorPdf, por lo que cada
  # etiqueta del lote tiene exactamente la misma composición que su PDF solo.
  module LoteEtiqueta
    A4_ANCHO_PT = Dimensiones.pt(210)
    A4_ALTO_PT  = Dimensiones.pt(297)

    # Margen exterior de la hoja y separación entre celdas (pt).
    MARGEN_PT = 20.0
    HUECO_PT  = 8.0

    # Nombre del PDF de lote dentro del directorio de salida (no cambia aunque
    # se genere con una hoja de tamaño distinto a A4).
    NOMBRE_ARCHIVO = 'lote_A4.pdf'

    module_function

    # Calcula la cuadrícula: [columnas, filas, etiquetas_por_hoja].
    # Siempre devuelve al menos 1×1.
    def grarilla(ancho_pagina_pt:, alto_pagina_pt:, ancho_etiqueta_pt:,
                 alto_etiqueta_pt:, margen_pt: MARGEN_PT, hueco_pt: HUECO_PT)
      columnas = ((ancho_pagina_pt - (2 * margen_pt) + hueco_pt) / (ancho_etiqueta_pt + hueco_pt)).floor
      filas    = ((alto_pagina_pt - (2 * margen_pt) + hueco_pt) / (alto_etiqueta_pt + hueco_pt)).floor
      columnas = 1 if columnas < 1
      filas    = 1 if filas < 1
      [columnas, filas, columnas * filas]
    end

    # Posición top-down de la celda i-ésima dentro de su hoja.
    def celda(indice, columnas, ancho_etiqueta_pt:, alto_etiqueta_pt:,
              margen_pt: MARGEN_PT, hueco_pt: HUECO_PT)
      col = indice % columnas
      fila = (indice / columnas).floor
      [margen_pt + (col * (ancho_etiqueta_pt + hueco_pt)),
       margen_pt + (fila * (alto_etiqueta_pt + hueco_pt))]
    end

    # Etiquetas que caben en una hoja (misma firma que `grarilla`).
    def por_hoja(ancho_pagina_pt:, alto_pagina_pt:, ancho_etiqueta_pt:,
                 alto_etiqueta_pt:, margen_pt: MARGEN_PT, hueco_pt: HUECO_PT)
      grarilla(ancho_pagina_pt: ancho_pagina_pt, alto_pagina_pt: alto_pagina_pt,
               ancho_etiqueta_pt: ancho_etiqueta_pt, alto_etiqueta_pt: alto_etiqueta_pt,
               margen_pt: margen_pt, hueco_pt: hueco_pt)[2]
    end

    # Nº de páginas necesarias para `total` etiquetas (al menos 1; una hoja
    # limpia si no hay etiquetas, útil para calibración/corte).
    def paginas(total, **kwargs)
      por_total = por_hoja(**kwargs)
      total.zero? || total.nil? ? 1 : ((total - 1) / por_total) + 1
    end

    # Genera el PDF del lote. Devuelve [columnas, filas, hojas]. Con etiquetas
    # vacías genera una hoja A4 limpia (útil para calibración/corte).
def generar(etiquetas, ruta, ancho_pagina_pt: A4_ANCHO_PT, alto_pagina_pt: A4_ALTO_PT,
              ancho_etiqueta_pt:, alto_etiqueta_pt:,
              margen_pt: MARGEN_PT, hueco_pt: HUECO_PT,
              tipo_codigo: LayoutEtiqueta::TIPO_CODE128)
      columnas, filas, por_hoja = grarilla(
        ancho_pagina_pt: ancho_pagina_pt, alto_pagina_pt: alto_pagina_pt,
        ancho_etiqueta_pt: ancho_etiqueta_pt, alto_etiqueta_pt: alto_etiqueta_pt,
        margen_pt: margen_pt, hueco_pt: hueco_pt
      )

      hojas = etiquetas.empty? ? 1 : ((etiquetas.size - 1) / por_hoja) + 1

      pagina = [ancho_pagina_pt, alto_pagina_pt]
      Prawn::Document.generate(ruta, page_size: pagina, margin: 0) do |pdf|
        etiquetas.each_with_index do |etiqueta, i|
          pdf.start_new_page(page_size: pagina, margin: 0) if (i % por_hoja).zero? && i.positive?

          layout = LayoutEtiqueta.calcular(etiqueta,
                                           ancho_pt: ancho_etiqueta_pt,
                                           alto_pt: alto_etiqueta_pt,
                                           tipo_codigo: tipo_codigo)
          origen_x, origen_y = celda(i % por_hoja, columnas,
                                     ancho_etiqueta_pt: ancho_etiqueta_pt,
                                     alto_etiqueta_pt: alto_etiqueta_pt,
                                     margen_pt: margen_pt, hueco_pt: hueco_pt)

          dibujador = DibujadorPdf.new(pdf, alto_pagina: alto_pagina_pt,
                                        origen_x: origen_x, origen_y: origen_y)
          DibujoEtiqueta.dibujar(dibujador, layout)
        end
      end

      [columnas, filas, hojas]
    end
  end
end