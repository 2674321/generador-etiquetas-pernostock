# frozen_string_literal: true

module GeneradorEtiquetas
  # Una fila procesada por la máquina. `estado` ∈
  #   :generada   → PDF creado correctamente
  #   :duplicada  → mismo código ya generado (se omite)
  #   :invalida   → código vacío o no imprimible como Code128
  #   :error      → fallo al generar el PDF
  Resultado = Struct.new(:fila, :codigo, :descripcion, :estado, :archivo, :error, keyword_init: true) do
    def generada?   = estado == :generada
    def duplicada?  = estado == :duplicada
    def invalida?   = estado == :invalida
    def con_error?  = estado == :error
  end

  # Resumen de una ejecución: cada fila con su estado y los totales.
  class Reporte
    attr_reader :resultados, :directorio, :ancho_pt, :alto_pt

    def initialize(directorio:, ancho_pt:, alto_pt:)
      @directorio = directorio
      @ancho_pt   = ancho_pt
      @alto_pt    = alto_pt
      @resultados = []
    end

    def <<(r)
      resultados << r
      self
    end

    def generadas = resultados.count(&:generada?)
    def duplicadas = resultados.count(&:duplicada?)
    def invalidas = resultados.count(&:invalida?)
    def errores = resultados.count(&:con_error?)
    def total = resultados.size

    def to_s
      lineas = []
      lineas << "Etiquetas generadas: #{generadas}"
      lineas << "Duplicados omitidos: #{duplicadas}" if duplicadas.positive?
      lineas << "Inválidas omitidas: #{invalidas}"     if invalidas.positive?
      lineas << "Con error: #{errores}"              if errores.positive?
      lineas << "Directorio de salida: #{directorio}"
      lineas.join("\n")
    end
  end
end