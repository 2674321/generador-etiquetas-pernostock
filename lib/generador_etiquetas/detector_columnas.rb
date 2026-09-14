# frozen_string_literal: true

require 'set'

module GeneradorEtiquetas
  # Detecta automáticamente las columnas "código" y "descripción" de una hoja
  # (XLSX/XLS/ODS/CSV) sin asumir el mismo orden ni la misma posición en todos
  # los documentos, y de paso localiza la fila de encabezado si existe.
  #
  # Estrategia en dos pasos:
  #   1) Fila de encabezado: se buscan sinónimos exactos de "código" y
  #      "descripción" en la primera fila que los contenga ("Código", "SKU",
  #      "Parte", "Descripción", "Nombre", …).
  #   2) Si falta alguno, heurística por contenido: los códigos tienden a ser
  #      breves, sin espacios y con dígitos; las descripciones a ser texto con
  #      palabras y espacios.
  class DetectorColumnas
    ENCABEZADO_CODIGO = %w[
      codigo cod sku id articulo part code reference referencia item
      upc ean etiqueta codigo_articulo codigo_barras cod_articulo
    ].freeze

    ENCABEZADO_DESCRIPCION = %w[
      descripcion desc description nombre denominacion detalle texto
      descripcion_articulo nombre_articulo
    ].freeze

    SINONIMOS = {
      codigo: ENCABEZADO_CODIGO,
      descripcion: ENCABEZADO_DESCRIPCION
    }.freeze

    # matriz: filas [[numero_fila, [celdas…]], …] con celdas ya convertidas a
    # texto. Devuelve { codigo:, descripcion:, encabezado: (nº fila o nil) }.
    def roles(matriz)
      return { codigo: 0, descripcion: 1, encabezado: nil } if matriz.empty?

      encabezado, mapeo = localizar_encabezado(matriz)
      datos = encabezado ? matriz.reject { |n, _| n == encabezado } : matriz

      rol_por_columna = mapeo || {}
      columnas_data = columnas_con_datos(datos)

      if !rol_por_columna.key?(:codigo)
        rol_por_columna[:codigo] = columna_codigo(datos, columnas_data)
      end
      if !rol_por_columna.key?(:descripcion)
        libres = columnas_data - [rol_por_columna[:codigo]]
        rol_por_columna[:descripcion] =
          columna_descripcion(datos, libres) || rol_por_columna[:codigo]
      end

      rol_por_columna[:encabezado] = encabezado
      rol_por_columna
    end

    private

    # Fila de encabezado: la primera fila con una celda que coincida por
    # sinónimo exacto con "código" o "descripción". Devuelve [nº_fila, {rol:
    # índice}] con los roles encontrados (pueden quedar incompletos).
    def localizar_encabezado(matriz)
      sinonimos = {
        codigo: SINONIMOS[:codigo].map { |s| normalizar(s) }.to_set,
        descripcion: SINONIMOS[:descripcion].map { |s| normalizar(s) }.to_set
      }

      matriz.each do |numero_fila, celdas|
        hallados = {}
        celdas.each_with_index do |valor, indice|
          clave = normalizar(valor)
          hallados[:codigo] = indice if sinonimos[:codigo].include?(clave)
          hallados[:descripcion] = indice if sinonimos[:descripcion].include?(clave)
        end
        return [numero_fila, hallados] unless hallados.empty?
      end
      [nil, nil]
    end

    def columnas_con_datos(matriz)
      total = matriz.flat_map { |_, celdas| celdas }.size
      columnas = matriz.first[1].size
      (0...columnas).select do |indice|
        matriz.any? { |_, celdas| !celdas[indice].to_s.empty? }
      end
    end

    def columna_codigo(matriz, columnas)
      return 0 if columnas.empty?

      mejores = columnas.sort_by do |indice|
        -puntuacion_codigo(matriz, indice)
      end
      escogida = mejores.first
      return 0 if puntuacion_codigo(matriz, escogida) <= 0

      escogida
    end

    def columna_descripcion(matriz, columnas)
      return nil if columnas.empty?

      escogida = columnas.max_by { |indice| puntuacion_descripcion(matriz, indice) }
      escogida if puntuacion_descripcion(matriz, escogida) > 0.2
    end

    def puntuacion_codigo(matriz, indice)
      valores = matriz.map { |_, celdas| celdas[indice].to_s }.reject(&:empty?)
      return -1_000_000 if valores.size < 2

      con_espacios = valores.count { |v| v.include?(' ') }
      sin_digitos = valores.count { |v| v !~ /\d/ }
      en_mayusculas = valores.count { |v| v == v.upcase && v =~ /[A-Z]/ }
      cortos = valores.count { |v| v.length <= 14 }
      unicos = valores.uniq.size

      (1.0 - (con_espacios / valores.size.to_f)) * 2.5 +
        (1.0 - (sin_digitos / valores.size.to_f)) * 1.5 +
        (en_mayusculas / valores.size.to_f) * 0.6 +
        (cortos / valores.size.to_f) * 0.4 +
        (unicos / valores.size.to_f) * 0.3
    end

    def puntuacion_descripcion(matriz, indice)
      valores = matriz.map { |_, celdas| celdas[indice].to_s }.reject(&:empty?)
      return -1_000_000 if valores.size < 2

      con_espacios = valores.count { |v| v.include?(' ') }
      con_minusculas = valores.count { |v| v =~ /[a-z]/ && v != v.upcase }
      largas = valores.count { |v| v.length > 8 }
      multi_palabra = valores.count { |v| v.split(/\s+/).size >= 2 }

      (con_espacios / valores.size.to_f) * 2.0 +
        (con_minusculas / valores.size.to_f) * 1.0 +
        (largas / valores.size.to_f) * 0.5 +
        (multi_palabra / valores.size.to_f) * 0.5
    end

    def normalizar(texto)
      texto.to_s.downcase
            .tr('áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunaeiouun')
            .tr('_', ' ')
            .tr('-', ' ')
            .gsub(/\s+/, ' ')
            .strip
    end
  end
end