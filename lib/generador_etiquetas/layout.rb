# frozen_string_literal: true

module GeneradorEtiquetas
  # Cálculo puro (sin Prawn ni Cairo) de la composición de una etiqueta.
  # Sistema de coordenadas: ORIGEN ARRIBA-IZQUIERDA, unidades en pt.
  #
  #   +------------------------------------+
  #   | descripción (hasta 2 líneas, bold) |
  #   |                                    |
  #   |       ||||||||||||||||||||          |  <- código de barras Code128
  #   |      PET-1001                      |  <- código legible
  #   +------------------------------------+
  #
  # El mismo Layout alimenta tanto al generador PDF como a la vista previa,
  # garantizando que lo que se ve es exactamente lo que se imprime.
  Layout = Struct.new(
    :pagina_ancho, :pagina_alto,
    :lineas_desc, :codigo_texto,
    :barras, :encoding,
    :padding, :ancho_util,
    :y_desc_inicio, :alto_linea_desc,
    :tamano_desc, :tamano_codigo,
    :y_codigo_inicio, :alto_codigo,
    keyword_init: true
  )

  Barras = Struct.new(:x, :y, :ancho, :alto, :xdim, :modulos, keyword_init: true)

  module LayoutEtiqueta
    HUECO_PT = 5.0
    ANCHO_POR_CARACTER = 0.56
    MIN_ALTO_BARRAS_PT = 18.0
    MIN_XDIM_PT = 0.5

    module_function

    def calcular(etiqueta, ancho_pt:, alto_pt:)
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

      # Las barras se centran; módulos en unidades xdim.
      encoding = etiqueta.code128_encoding
      modulos = encoding.length
      xdim = xdim_ajustado(ancho_util, modulos)
      ancho_barras = modulos * xdim
      x_barras = padding + ((ancho_util - ancho_barras) / 2.0).round(2)

      Layout.new(
        pagina_ancho: ancho_pt,
        pagina_alto: alto_pt,
        lineas_desc: lineas,
        codigo_texto: etiqueta.codigo,
        encoding: encoding,
        padding: padding,
        ancho_util: ancho_util,
        y_desc_inicio: y_desc_inicio,
        alto_linea_desc: altura_linea_desc,
        tamano_desc: tam_desc,
        tamano_codigo: tam_codigo,
        y_codigo_inicio: y_codigo_inicio,
        alto_codigo: alto_codigo,
        barras: Barras.new(
          x: x_barras, y: y_barras,
          ancho: ancho_barras, alto: alto_barras,
          xdim: xdim, modulos: modulos
        )
      )
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