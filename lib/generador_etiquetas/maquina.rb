# frozen_string_literal: true

module GeneradorEtiquetas
  # Orquestador: lee el libro, valida, deduplica, filtra y genera los PDFs.
  # Solo depende del núcleo (sin GTK), por lo que es reutilizable desde la CLI
  # y desde la GUI.
  class Maquina
    attr_reader :salida, :ancho_pt, :alto_pt

    def initialize(salida: nil, ancho_mm: Dimensiones::ANCHO_POR_DEFECTO_MM,
                   alto_mm: Dimensiones::ALTO_POR_DEFECTO_MM)
      @salida = salida || File.join(Dir.pwd, 'salida')
      @salida = File.expand_path(@salida)
      @ancho_pt, @alto_pt = Dimensiones.pagina(ancho_mm: ancho_mm, alto_mm: alto_mm)
    end

    # procesar(ruta, filtrar: nil, cantidad: nil, permitir_duplicados: false,
    #          omitir_encabezado: true, hoja: 0, en_progreso: nil, lote: false)
    #   ruta               → XLSX/XLS/ODS/CSV con códigos en columna A y descripción en B.
    #   filtrar            → texto; solo se procesan códigos/descripciones que lo contengan.
    #   cantidad           → máx. etiquetas a generar (nil = todas).
    #   permitir_duplicados→ si false, los códigos repetidos se omiten y se reportan.
    #   omitir_encabezado  → si true, salta una primera fila tipo "Código/ETIQUETA/SKU".
    #   hoja               → índice (0, 1, …) o nombre de la hoja a leer.
    #   en_progreso        → callback para UI; se invoca como at(hechas, total)
    #                        tras cada fila (nil/no-op si no se pasa).
    #   lote               → si true, además genera `lote_A4.pdf` con todas las
    #                        generadas en cuadrícula sobre hojas A4.
    #   lote_margen_pt    → margen de la hoja del lote (pt; defecto LoteEtiqueta::MARGEN_PT).
    #   lote_hueco_pt     → separación entre celdas del lote (pt; defecto LoteEtiqueta::HUECO_PT).
    #   lote_pagina_pt    → [ancho, alto] de la hoja del lote (pt; por defecto A4).
    def procesar(ruta, filtrar: nil, cantidad: nil, permitir_duplicados: false,
                 omitir_encabezado: true, hoja: 0, en_progreso: nil, lote: false,
                 lote_margen_pt: LoteEtiqueta::MARGEN_PT, lote_hueco_pt: LoteEtiqueta::HUECO_PT,
                 lote_pagina_pt: nil, tipo_codigo: LayoutEtiqueta::TIPO_CODE128)
      filas, _omitio_encabezado = Libro.cargar(ruta,
                                               omitir_encabezado: omitir_encabezado,
                                               hoja: hoja)
      tipo_codigo = LayoutEtiqueta.normalizar_tipo(tipo_codigo)
      FileUtils.mkdir_p(salida)

      reporte = Reporte.new(directorio: salida, ancho_pt: ancho_pt, alto_pt: alto_pt)
      vistos = {}
      generadas = 0
      generadas_etiquetas = []
      total = filas.size

      filas.each_with_index do |fila, indice|
        codigo = fila.codigo
        descripcion = fila.descripcion

        if filtrar && !filtrar.empty?
          next unless codigo.include?(filtrar) || descripcion.include?(filtrar)
        end

        resultado = Resultado.new(fila: fila.fila, codigo: codigo, descripcion: descripcion)

        unless Etiqueta.new(codigo: codigo, descripcion: descripcion).codigo_valido?
          reporte << resultado.tap { |r| r.estado = :invalida }
          en_progreso&.call(indice + 1, total)
          next
        end

        if !permitir_duplicados && vistos[codigo]
          reporte << resultado.tap { |r| r.estado = :duplicada }
          en_progreso&.call(indice + 1, total)
          next
        end

        break if cantidad && generadas >= cantidad

        vistos[codigo] = true
        generadas += 1
        ruta_pdf = generar_pdf(codigo, descripcion, fila.fila, tipo_codigo)
        reporte << ruta_pdf
        if ruta_pdf.generada?
          generadas_etiquetas << Etiqueta.new(codigo: codigo, descripcion: descripcion)
        end
        en_progreso&.call(indice + 1, total)
      end

      generar_lote(reporte, generadas_etiquetas, lote_margen_pt, lote_hueco_pt, lote_pagina_pt, tipo_codigo) if lote

      reporte
    end

    private

    # Genera el PDF de lote A4 con las etiquetas ya generadas y lo añade al
    # reporte como un resultado más (filas: 0). Con cero etiquetas no lo crea.
    def generar_lote(reporte, etiquetas, margen_pt = LoteEtiqueta::MARGEN_PT,
                   hueco_pt = LoteEtiqueta::HUECO_PT, pagina_pt = nil,
                   tipo_codigo = LayoutEtiqueta::TIPO_CODE128)
      return if etiquetas.empty?

      pagina_pt ||= [LoteEtiqueta::A4_ANCHO_PT, LoteEtiqueta::A4_ALTO_PT]
      ancho_pagina_pt, alto_pagina_pt = pagina_pt
      personalizada = pagina_pt != [LoteEtiqueta::A4_ANCHO_PT, LoteEtiqueta::A4_ALTO_PT]

      ruta_lote = File.join(salida, LoteEtiqueta::NOMBRE_ARCHIVO)
      descripcion = +"#{etiquetas.size} etiquetas"
      if personalizada
        descripcion << format(' · hoja %.1f×%.1f mm',
                              ancho_pagina_pt / Dimensiones::MM_A_PT,
                              alto_pagina_pt / Dimensiones::MM_A_PT)
      end
      resultado = Resultado.new(fila: 0, codigo: 'LOTE A4',
                                descripcion: descripcion,
                                estado: :error, archivo: ruta_lote)
      begin
        LoteEtiqueta.generar(etiquetas, ruta_lote,
                             ancho_pagina_pt: ancho_pagina_pt, alto_pagina_pt: alto_pagina_pt,
                             ancho_etiqueta_pt: ancho_pt, alto_etiqueta_pt: alto_pt,
                             margen_pt: margen_pt, hueco_pt: hueco_pt,
                             tipo_codigo: tipo_codigo)
        resultado.estado = :lote
      rescue StandardError => e
        resultado.error = mensaje_corto(e)
      end
      reporte << resultado
    end

    def generar_pdf(codigo, descripcion, fila, tipo_codigo = LayoutEtiqueta::TIPO_CODE128)
      etiqueta = Etiqueta.new(codigo: codigo, descripcion: descripcion, fila: fila)
      ruta_pdf = File.join(salida, nombre_archivo(codigo))

      resultado = Resultado.new(fila: fila, codigo: codigo, descripcion: descripcion,
                                estado: :error, archivo: ruta_pdf)
      begin
        PdfEtiqueta.generar(etiqueta, ruta_pdf, ancho_pt: ancho_pt, alto_pt: alto_pt,
                            tipo_codigo: tipo_codigo)
        resultado.estado = :generada
      rescue StandardError => e
        resultado.error = mensaje_corto(e)
      end
      resultado
    rescue StandardError => e
      Resultado.new(fila: fila, codigo: codigo, descripcion: descripcion,
                    estado: :error, archivo: ruta_pdf, error: mensaje_corto(e))
    end

    def nombre_archivo(codigo)
      sanitizado = codigo.gsub(/[^A-Za-z0-9._-]+/, '_').gsub(/[._-]+\z/, '')
      "#{sanitizado.empty? ? 'etiqueta' : sanitizado}.pdf"
    end

    def mensaje_corto(error)
      error.message.to_s.lines.first.to_s.strip[0, 200]
    end
  end
end