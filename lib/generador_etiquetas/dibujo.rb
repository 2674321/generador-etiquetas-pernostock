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

      barras = layout.barras
      layout.encoding.each_char.with_index do |modulo, i|
        next if modulo == '0'

        dibujador.rect(
          barras.x + (i * barras.xdim), barras.y,
          barras.xdim, barras.alto
        )
      end

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
  end
end