# frozen_string_literal: true

# Dibujo de la etiqueta sobre un "dibujador" abstracto, de modo que el PDF
# (Prawn, coordenadas bottom-up) y la vista previa (Cairo, top-down) compartan
# exactamente la misma lógica de composición.
#
# Las coordenadas que recibe el dibujador SIEMPRE son top-down en puntos,
# relativas a la esquina superior izquierda de la página.
module GeneradorEtiquetas
  module DibujoEtiqueta
    module_function

    FAMILIA_ETIQUETA = 'Helvetica'
    FAMILIA_CODIGO = 'Courier'

    # Dibuja la etiqueta completa a partir de un Layout (etiqueta ya compuesta).
    def dibujar(dibujador, layout)
      dibujador.fondo_blanco(layout.pagina_ancho, layout.pagina_alto)

      layout.lineas_desc.each_with_index do |linea, i|
        dibujador.texto(linea,
                        x: layout.padding,
                        y: layout.y_desc_inicio + (i * layout.alto_linea_desc),
                        tamano: layout.tamano_desc,
                        negrita: true,
                        familia: FAMILIA_ETIQUETA,
                        alto_linea: layout.alto_codigo,
                        ancho: layout.ancho_util)
      end

      dibujar_barras(dibujador, layout) if layout.barras
      dibujar_qr(dibujador, layout) if layout.qr

      dibujador.texto(layout.codigo_texto.to_s,
                      x: layout.padding,
                      y: layout.y_codigo_inicio,
                      tamano: layout.tamano_codigo,
                      negrita: true,
                      familia: FAMILIA_CODIGO,
                      alto_linea: layout.alto_codigo,
                      ancho: layout.ancho_util,
                      align: :center)
    end

    # Barras Code128: un rectángulo por módulo encendido.
    def dibujar_barras(dibujador, layout)
      barras = layout.barras
      layout.encoding.each_char.with_index do |modulo, i|
        next if modulo == '0'

        dibujador.rect(
          barras.x + (i * barras.xdim), barras.y,
          barras.xdim, barras.alto
        )
      end
    end

    # QR: una celda cuadrada por módulo encendido de la matriz.
    def dibujar_qr(dibujador, layout)
      qr = layout.qr
      lado_celda = qr[:lado].to_f / qr[:modulos]
      qr[:matriz].each_with_index do |fila, fy|
        fila.each_with_index do |encendido, fx|
          next unless encendido

          dibujador.rect(
            qr[:x] + (fx * lado_celda), qr[:y] + (fy * lado_celda),
            lado_celda, lado_celda
          )
        end
      end
    end
  end
end