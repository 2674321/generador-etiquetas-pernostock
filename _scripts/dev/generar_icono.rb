#!/usr/bin/env ruby
# frozen_string_literal: true

# Genera el icono de la aplicación PernoLabel con Cairo (sin dependencias de
# escritorio además de cairo): "lente" verde con una placa blanca que muestra un
# código de barras Code128 estilizado y el código QR real del texto PERNOLABEL.
#
# Uso:
#   ruby _scripts/dev/generar_icono.rb [directorio_salida]
#
# Escribe pernolabel-{48,64,128,256,512}.png en packaging/icons por defecto.

require 'cairo'

require_relative '../../lib/generador_etiquetas'

ICONO_DIR = File.expand_path('../../packaging/icons', __dir__)
TAMANOS = [48, 64, 128, 256, 512].freeze
PALETA = {
  tope: [46, 125, 84],
  fondo: [21, 83, 45],
  placa: [248, 252, 249],
  placa_borde: [205, 227, 214],
  tinta: [16, 37, 27],
  texto: [215, 240, 226]
}.freeze

# Módulos del QR real del texto de marca (21×21, nivel M).
MATRIZ = GeneradorEtiquetas::Etiqueta.new(codigo: 'PERNOLABEL').qr_modules
# Barras Code128 estilizadas: patrón determinista de módulos.
BARRAS = [
  1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1,
  1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0
].freeze

def color(parte)
  PALETA.fetch(parte).map { |v| v / 255.0 }
end

def modulo_redondeado(cr, x, y, ancho, alto, radio)
  cr.tap do |c|
    c.new_path
    c.move_to(x + radio, y)
    c.line_to(x + ancho - radio, y)
    c.arc(x + ancho - radio, y + radio, radio, -Math::PI / 2, 0)
    c.line_to(x + ancho, y + alto - radio)
    c.arc(x + ancho - radio, y + alto - radio, radio, 0, Math::PI / 2)
    c.line_to(x + radio, y + alto)
    c.arc(x + radio, y + alto - radio, radio, Math::PI / 2, Math::PI)
    c.line_to(x, y + radio)
    c.arc(x + radio, y + radio, radio, Math::PI, Math::PI * 1.5)
    c.close_path
  end
end

def dibujar_qr(cr, x, y, lado, modulos = MATRIZ)
  paso = lado.to_f / modulos.size
  (0...modulos.size).each do |fila|
    modulos[fila].each_with_index do |encendido, columna|
      next unless encendido

      cr.rectangle(x + columna * paso, y + fila * paso, paso, paso)
      cr.fill
    end
  end
end

def dibujar_barras(cr, x, y, ancho, alto)
  paso = ancho.to_f / BARRAS.size
  cr.set_source_rgb(*color(:tinta))
  BARRAS.each_with_index do |encendido, i|
    next unless encendido == 1

    cr.rectangle(x + (i * paso), y, paso, alto)
  end
  cr.fill
end

def dibujar_icono(canvas)
  cr = Cairo::Context.new(canvas)
  n = canvas.width
  u = n / 512.0 # unidad proporcional (diseñado a 512)

  # Fondo: recuadro redondeado con degradado verde.
  modulo_redondeado(cr, 0, 0, n, n, 96 * u)
  grad = Cairo::LinearPattern.new(0, 0, 0, n)
  grad.add_color_stop_rgb(0, *PALETA[:tope].map { |v| v / 255.0 })
  grad.add_color_stop_rgb(1, *PALETA[:fondo].map { |v| v / 255.0 })
  cr.set_source(grad)
  cr.fill

  # Placa rotada (-6°): base blanca con etiqueta.
  ancho_placa = 420 * u
  alto_placa = 250 * u
  x_placa = (n - ancho_placa) / 2.0
  y_placa = (n - alto_placa) / 2.0 - (n < 128 ? 8 * u : 20 * u)
  cr.save
  cr.translate(x_placa + ancho_placa / 2.0, y_placa + alto_placa / 2.0)
  cr.rotate(-6 * Math::PI / 180)
  cr.translate(-(x_placa + ancho_placa / 2.0), -(y_placa + alto_placa / 2.0))

  modulo_redondeado(cr, x_placa, y_placa, ancho_placa, alto_placa, 28 * u)
  cr.set_source_rgb(*color(:placa))
  cr.fill
  cr.set_line_width(6 * u)
  cr.set_source_rgb(*color(:placa_borde))
  cr.stroke

  # Contenido: barras a la izquierda, QR real a la derecha.
  margen_x = 40 * u
  margen_y = 34 * u
  alto_interior = alto_placa - (margen_y * 2)
  ancho_barras = ancho_placa * 0.5
  lado_qr = [alto_interior, (ancho_placa * 0.36)].min

  dibujar_barras(cr, x_placa + margen_x, y_placa + margen_y, ancho_barras, alto_interior)
  x_qr = x_placa + ancho_placa - margen_x - lado_qr
  cr.set_source_rgb(*color(:tinta))
  dibujar_qr(cr, x_qr, y_placa + margen_y, lado_qr)

  cr.restore

  # Palabra/identidad en las variantes grandes.
  if n >= 128
    cr.select_font_face('sans-serif', Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_BOLD)
    cr.set_font_size(64 * (n / 512.0))
    cr.set_source_rgb(*color(:texto))
    cr.move_to((n - cr.text_extents('PernoLabel').width) / 2.0, n - 66 * u)
    cr.show_text('PernoLabel')
  end

  cr
end

salida = ARGV[0] || ICONO_DIR
FileUtils.mkdir_p(salida)

TAMANOS.each do |tamano|
  superficie = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, tamano, tamano)
  dibujar_icono(superficie)
  ruta = File.join(salida, "pernolabel-#{tamano}.png")
  superficie.write_to_png(ruta)
  puts "  ✓ #{ruta}"
end