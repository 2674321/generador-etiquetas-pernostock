# frozen_string_literal: true

# Geometría de las etiquetas. Todas las medidas se expresan en puntos (pt)
# para Prawn y en coordenadas de diseño para la vista previa (Cairo).
#
# Un milímetro = 72/25.4 puntos.
module GeneradorEtiquetas
  module Dimensiones
    MM_A_PT = 72.0 / 25.4

    ANCHO_POR_DEFECTO_MM = 100
    ALTO_POR_DEFECTO_MM   = 50

    PADDING_PT = 9.0

    # Texto de descripción (arriba) y código legible (bajo las barras).
    TAMANO_DESCRIPCION_PT = 10.0
    TAMANO_CODIGO_PT      = 9.0

    def self.pt(milimetros)
      milimetros.to_f * MM_A_PT
    end

    def self.pagina(ancho_mm:, alto_mm:)
      [pt(ancho_mm), pt(alto_mm)]
    end

    def self.tamano_por_defecto
      [pt(ANCHO_POR_DEFECTO_MM), pt(ALTO_POR_DEFECTO_MM)]
    end
  end
end