# frozen_string_literal: true

module GeneradorEtiquetas
  # Una etiqueta a generar: un código (obligatorio, imprimible en Code128)
  # y una descripción opcional que se muestra sobre las barras.
  class Etiqueta
    PATRON_CODIGO_VALIDO = /\A[\x20-\x7E]+\z/

    attr_reader :codigo, :descripcion, :fila

    def initialize(codigo:, descripcion: "", fila: nil)
      @codigo      = codigo.to_s.strip
      @descripcion = descripcion.to_s.strip
      @fila        = fila
    end

    def codigo_valido?
      !codigo.empty? && PATRON_CODIGO_VALIDO.match?(codigo)
    end

    def code128_encoding
      raise ArgumentError, "Código no válido para Code128: #{codigo.inspect}" unless codigo_valido?

      # Barby calcula el dígito verificador; solo se usa para obtener la
      # secuencia de módulos (1 = barra) y el ancho final.
      Barby::Code128.new(codigo).encoding
    end

    # Matriz booleana (fila → columna) del QR que codifica el código.
    # Nivel M (medio); el tamaño del símbolo depende de la longitud.
    def qr_modules
      raise ArgumentError, "Código no válido para QR: #{codigo.inspect}" unless codigo_valido?

      RQRCode::QRCode.new(codigo, level: :m).modules
    end
  end
end