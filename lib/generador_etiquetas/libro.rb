# frozen_string_literal: true

module GeneradorEtiquetas
  # Lectura portable de la hoja de cálculo (Roo).
  # Columna A = código, columna B = descripción (opcional).
  class Libro
    EXTENSIONES = %w[.xlsx .xls .xlsm .ods].freeze

    Fila = Struct.new(:codigo, :descripcion, :fila, keyword_init: true)

    attr_reader :ruta

    def self.cargar(ruta_xlsx, omitir_encabezado: true)
      new(ruta_xlsx).leer(omitir_encabezado: omitir_encabezado)
    end

    def initialize(ruta_xlsx)
      @ruta = File.expand_path(ruta_xlsx.to_s)
    end

    # Devuelve [+filas+, +encabezado_omitido+].
    # Cada fila es {codigo:, descripcion:, fila:}. Las celdas vacías se
    # devuelven igualmente para que el reporte pueda indicarlas.
    def leer(omitir_encabezado: true)
      validar_ruta!
      libro = Roo::Spreadsheet.open(ruta)
      hoja  = libro.sheet(0)
      filas = []

      (hoja.first_row..hoja.last_row).each do |numero_fila|
        datos = hoja.row(numero_fila).to_a
        codigo = celda(datos, 0)
        descripcion = celda(datos, 1)

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

    # Encabezamientos como "Código", "ETIQUETA", "SKU" no contienen dígitos.
    def solo_letras_sin_digitos?(texto)
      return false if texto.nil?
      return false unless texto.match?(/[A-Za-zÁÉÍÓÚÑáéíóúñ]/)
      return false if texto.match?(/\d/)

      true
    end
  end
end