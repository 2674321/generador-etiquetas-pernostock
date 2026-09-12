# frozen_string_literal: true

module GeneradorEtiquetas
  # Cálculo puro (sin Prawn ni Cairo) de la composición de una etiqueta.
  # Sistema de coordenadas: ORIGEN ARRIBA-IZQUIERDA, unidades en pt.
  #
  #   +------------------------------------+
  #   | descripción (hasta 2 líneas, bold) |
  #   |                                    |
  #   |       ||||||||||||||||||||          |  <- Code128 (barras) y/o QR
  #   |      PET-1001                      |  <- código legible
  #   +------------------------------------+
  #
  # El tipo de código (barras Code128, QR o ambos) condiciona la geometría de
  # la zona central. El mismo Layout alimenta tanto al generador PDF como a la
  # vista previa, garantizando que lo que se ve es exactamente lo que se imprime.
  Layout = Struct.new(
    :pagina_ancho, :pagina_alto,
    :lineas_desc, :codigo_texto,
    :barras, :encoding, :qr,
    :padding, :ancho_util,
    :y_desc_inicio, :alto_linea_desc,
    :tamano_desc, :tamano_codigo,
    :y_codigo_inicio, :alto_codigo,
    keyword_init: true
  )

  # Geometría de un conjunto de barras Code128.
  Barras = Struct.new(:x, :y, :ancho, :alto, :xdim, :modulos, keyword_init: true)

  module LayoutEtiqueta
    TIPO_CODE128 = :code128
    TIPO_QR = :qr
    TIPO_AMBOS = :ambos
    TIPOS = {
      'code128' => TIPO_CODE128, 'barras' => TIPO_CODE128,
      'qr' => TIPO_QR,
      'ambos' => TIPO_AMBOS
    }.freeze

    HUECO_PT = 5.0
    ANCHO_POR_CARACTER = 0.56
    MIN_ALTO_BARRAS_PT = 18.0
    MIN_XDIM_PT = 0.5
    # Proporción máxima del ancho útil que ocupa el QR en el modo "ambos".
    QR_ANCHO_BASE = 0.32
    GAP_QR_BARRAS_PT = 4.0

    module_function

    def calcular(etiqueta, ancho_pt:, alto_pt:, tipo_codigo: TIPO_CODE128)
      tipo = normalizar_tipo(tipo_codigo)
      padding = Dimensiones::PADDING_PT
      ancho_util = ancho_pt - (padding * 2)

      tam_desc = Dimensiones::TAMANO_DESCRIPCION_PT
      altura_linea_desc = tam_desc * 1.35
      lineas = envolver(etiqueta.descripcion, ancho_util, tam_desc)[0, 2]
      alto_desc = lineas.size * altura_linea_desc

      tam_codigo = Dimensiones::TAMANO_CODIGO_PT
      alto_codigo = tam_codigo * 1.5

      y_desc_inicio = padding
      y_codigo_fin  = alto_pt - padding
      y_codigo_inicio = y_codigo_fin - alto_codigo

      y_barras = y_desc_inicio + alto_desc + HUECO_PT
      alto_barras = y_codigo_inicio - HUECO_PT - y_barras
      alto_barras = MIN_ALTO_BARRAS_PT if alto_barras < MIN_ALTO_BARRAS_PT

      encoding = (tipo == TIPO_QR) ? nil : etiqueta.code128_encoding
      matriz   = (tipo == TIPO_CODE128) ? nil : etiqueta.qr_modules

      barras, qr = geometria_codigo(tipo, encoding, matriz, ancho_util, padding,
                                    y_barras, alto_barras)

      Layout.new(
        pagina_ancho: ancho_pt,
        pagina_alto: alto_pt,
        lineas_desc: lineas,
        codigo_texto: etiqueta.codigo,
        encoding: encoding,
        qr: qr,
        padding: padding,
        ancho_util: ancho_util,
        y_desc_inicio: y_desc_inicio,
        alto_linea_desc: altura_linea_desc,
        tamano_desc: tam_desc,
        tamano_codigo: tam_codigo,
        y_codigo_inicio: y_codigo_inicio,
        alto_codigo: alto_codigo,
        barras: barras
      )
    end

    # Normaliza cadena|símbolo → uno de los TIPO_*.
    def normalizar_tipo(tipo_codigo)
      clave = tipo_codigo.to_s.downcase
      TIPOS.fetch(clave) { raise ArgumentError, "Tipo de código no soportado: #{tipo_codigo.inspect}" }
    end

    # Geometría de la zona central según el tipo:
    #   code128 → barras centradas a todo el ancho útil; sin QR.
    #   qr      → símbolo cuadrado centrado; sin barras.
    #   ambos   → barras a la izquierda (encogidas) + QR cuadrado a la derecha.
    def geometria_codigo(tipo, encoding, matriz, ancho_util, padding,
                         y_barras, alto_barras)
      return [nil, nil] if encoding.nil? && matriz.nil?

      if tipo == TIPO_QR
        lado = [alto_barras, ancho_util].min
        return [nil, qr_geometria(matriz, padding + ((ancho_util - lado) / 2.0),
                                  y_barras, lado)]
      end

      if tipo == TIPO_AMBOS
        lado = [alto_barras, ancho_util * QR_ANCHO_BASE].min
        x_qr = padding + ancho_util - lado
        return [barras_geometria(encoding, padding, x_qr - GAP_QR_BARRAS_PT - padding,
                                 y_barras, alto_barras),
                qr_geometria(matriz, x_qr, y_barras, lado)]
      end

      barras = barras_geometria(encoding, padding, ancho_util, y_barras, alto_barras)
      [barras, nil]
    end

    # Barras Code128 centradas dentro de [x_inicio, x_inicio + ancho_disponible].
    def barras_geometria(encoding, x_inicio, ancho_disponible, y, alto)
      modulos = encoding.length
      xdim = xdim_ajustado(ancho_disponible, modulos)
      ancho_barras = modulos * xdim
      x = x_inicio + ((ancho_disponible - ancho_barras) / 2.0).round(2)
      Barras.new(x: x, y: y, ancho: ancho_barras, alto: alto, xdim: xdim, modulos: modulos)
    end

    def qr_geometria(matriz, x, y, lado)
      { x: x.round(2), y: y, lado: lado, modulos: matriz.size, matriz: matriz }
    end

    # Ajusta el ancho de módulo para que las barras ocupen el ancho útil.
    def xdim_ajustado(ancho_util, modulos)
      xdim = ((ancho_util / modulos) * 100).floor / 100.0
      xdim = MIN_XDIM_PT if xdim < MIN_XDIM_PT
      xdim
    end

    # Envuelve texto a palabras usando una estimación de ancho de carácter.
    def envolver(texto, ancho_pt, tamano)
      max_chars = (ancho_pt / (tamano * ANCHO_POR_CARACTER)).floor
      max_chars = 5 if max_chars < 5

      return [] if texto.nil? || texto.empty?

      lineas = []
      actual = +""
      texto.split(/\s+/).each do |palabra|
        if actual.empty?
          actual = +palabra
        elsif (actual.length + 1 + palabra.length) <= max_chars
          actual << " " << palabra
        else
          lineas << actual
          actual = +palabra
        end
      end
      lineas << actual unless actual.empty?
      lineas
    end
  end
end