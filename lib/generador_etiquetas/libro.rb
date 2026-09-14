# frozen_string_literal: true

module GeneradorEtiquetas
  # Lectura portable de la hoja de cálculo (Roo). Las columnas de "código" y
  # "descripción" se detectan automáticamente (DetectorColumnas) según la
  # organización del documento (XLSX/XLS/ODS/CSV): funciona con la descripción
  # antes que el código, con columnas adicionales o sin encabezado. Se puede
  # forzar el mapeo con `columnas: {codigo: 0, descripcion: 2}`.
  class Libro
    EXTENSIONES = %w[.xlsx .xls .xlsm .ods .csv].freeze

    Fila = Struct.new(:codigo, :descripcion, :fila, keyword_init: true)

    attr_reader :ruta

    def self.cargar(ruta_xlsx, omitir_encabezado: true, hoja: 0, columnas: nil)
      new(ruta_xlsx).leer(omitir_encabezado: omitir_encabezado, hoja: hoja,
                          columnas: columnas)
    end

    # Nombres de las hojas del libro (para selección manual).
    def self.hojas(ruta_xlsx)
      libro = new(ruta_xlsx)
      libro.send(:validar_ruta!)
      Roo::Spreadsheet.open(libro.ruta).sheets
    end

    def initialize(ruta_xlsx)
      @ruta = File.expand_path(ruta_xlsx.to_s)
    end

    # Devuelve [+filas+, +encabezado_omitido+].
    # Cada fila es {codigo:, descripcion:, fila:}. Las celdas vacías se
    # devuelven igualmente para que el reporte pueda indicarlas; las filas
    # completamente vacías se omiten. `columnas:` permite forzar el mapeo
    # {codigo: índice, descripcion: índice} en documentos atípicos.
    def leer(omitir_encabezado: true, hoja: 0, columnas: nil)
      validar_ruta!
      libro = Roo::Spreadsheet.open(ruta)
      seleccionada = elegir_hoja(libro, hoja)
      matriz = (seleccionada.first_row..seleccionada.last_row).map do |numero_fila|
        celdas = seleccionada.row(numero_fila).to_a.map { |valor| celda(valor) }
        [numero_fila, celdas]
      end

      roles = mapear_roles(matriz, columnas)
      indice_codigo = roles[:codigo].to_i
      indice_descripcion = roles[:descripcion].to_i

      filas = []
      matriz.each do |numero_fila, celdas|
        codigo = celdas[indice_codigo].to_s
        descripcion = celdas[indice_descripcion].to_s

        next if fila_vacia?(codigo, descripcion)

        if omitir_encabezado && roles[:encabezado]
          next if numero_fila == roles[:encabezado]
        elsif omitir_encabezado && filas.empty? &&
              solo_letras_sin_digitos?(codigo) && !descripcion.empty?
          next
        end

        filas << Fila.new(codigo: codigo, descripcion: descripcion, fila: numero_fila)
      end

      [filas, filas.first&.fila != 1]
    end

    private

    def mapear_roles(matriz, columnas)
      if columnas
        hash = columnas.is_a?(Hash) ? columnas : { codigo: columnas[0], descripcion: columnas[1] }
        { codigo: hash[:codigo] || 0,
          descripcion: hash[:descripcion] || 1,
          encabezado: nil }
      else
        DetectorColumnas.new.roles(matriz)
      end
    end

    def validar_ruta!
      raise ArgumentError, "Archivo no encontrado: #{ruta}" unless File.exist?(ruta)

      extension = File.extname(ruta).downcase
      return if EXTENSIONES.include?(extension)

      raise ArgumentError, "Formato no soportado (#{extension}). Se espera XLS/XLSX/ODS/CSV."
    end

    def celda(valor)
      valor.is_a?(Numeric) ? valor.to_s : valor.to_s.strip
    rescue StandardError
      ""
    end

    def elegir_hoja(libro, seleccion)
      nombres = libro.sheets.to_a
      if seleccion.is_a?(Numeric)
        indice = seleccion.to_i
        unless indice.between?(0, nombres.size - 1)
          raise ArgumentError, "La hoja #{indice} no existe. Hojas: #{nombres.join(', ')}"
        end

        libro.sheet(indice)
      else
        nombre = seleccion.to_s
        indice = nombres.index(nombre)
        unless indice
          raise ArgumentError, "Hoja '#{nombre}' no encontrada. Hojas: #{nombres.join(', ')}"
        end

        libro.sheet(indice)
      end
    end

    def fila_vacia?(codigo, descripcion)
      codigo.empty? && descripcion.empty?
    end

    # Encabezamientos como "Código", "ETIQUETA", "SKU" no contienen dígitos.
    def solo_letras_sin_digitos?(texto)
      return false if texto.nil?
      return false unless texto.match?(/[A-Za-zÁÉÍÓÚÑáéíóúñ]/)
      return false if texto.match?(/\d/)

      true
    end
  end
end