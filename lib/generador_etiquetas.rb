# frozen_string_literal: true

# Punto de entrada del núcleo de PernoLabel (sin GUI).
# Uso: require_relative 'generador_etiquetas'

require 'prawn'
require 'barby'
require 'barby/barcode/code_128'
require 'rqrcode'
require 'roo'
require 'roo-xls'
require 'fileutils'

require_relative 'generador_etiquetas/version'
require_relative 'generador_etiquetas/dimensiones'
require_relative 'generador_etiquetas/detector_columnas'
require_relative 'generador_etiquetas/etiqueta'
require_relative 'generador_etiquetas/libro'
require_relative 'generador_etiquetas/layout'
require_relative 'generador_etiquetas/dibujo'
require_relative 'generador_etiquetas/pdf'
require_relative 'generador_etiquetas/lote'
require_relative 'generador_etiquetas/reporte'
require_relative 'generador_etiquetas/maquina'