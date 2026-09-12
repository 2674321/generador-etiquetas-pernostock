# frozen_string_literal: true

module GeneradorEtiquetas
  # Lectura portable de la hoja de cálculo (Roo).
  # Columna A = código, columna B = descripción (opcional).
  class Libro
    EXTENSIONES = %w[.xlsx .xls .xlsm .ods].freeze

    Fila = Struct.new(:codigo, :descripcion, :fila, keyword_init: true)

    attr_reader :ruta

    def self.cargar(ruta_xlsx, omitir_encabezado: true, hoja: 0)
      new(ruta_xlsx).leer(omitir_encabezado: omitir_encabezado, hoja: hoja)
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
    # completamente vacías se omiten del reporte.
    def leer(omitir_encabezado: true, hoja: 0)
      validar_ruta!
      libro = Roo::Spreadsheet.open(ruta)
      seleccionada = elegir_hoja(libro, hoja)
      filas = []

      (seleccionada.first_row..seleccionada.last_row).each do |numero_fila|
        datos = seleccionada.row(numero_fila).to_a
        codigo = celda(datos, 0)
        descripcion = celda(datos, 1)

        next if fila_vacia?(codigo, descripcion)
        next if omitir_encabezado && filas.empty? && solo_letras_sin_digitos?(codigo) && !descripcion.empty?

        filas << Fila.new(codigo: codigo, descripcion: descripcion, fila: numero_fila)
      end

      [filas, filas.first&.fila != 1]
    end

    private

    def validar_ruta!
      raise ArgumentError, "Archivo no encontrado: #{ruta}" unless File.exist?(ruta)

      extension = File.extname(ruta).downcase
      return if EXTENSIONES.include?(extension)

      raise ArgumentError, "Formato no soportado (#{extension}). Se espera XLS/XLSX/ODS."
    end

    def celda(datos, indice)
      valor = datos[indice]
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