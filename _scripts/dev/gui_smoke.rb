#!/usr/bin/env ruby
# frozen_string_literal: true

# Prueba de humo de la GUI (REQUIERE display X11). Se ejecuta con:
#   DISPLAY=:0 rake gui_smoke
# Construye la ventana SIN mostrarla y ejercita por código:
#   1. selección de archivo vía FileChooserButton (file-set en uso real)
#   2. refresco del selector de hoja
#   3. generar() en hilo + GLib::Idle (progreso y resultados)
#   4. rellenado del TreeView y selección -> actualizar_previa
#   5. dibujo de la previa con Cairo offscreen (misma curva que el 'draw')
require 'fileutils'
require 'tmpdir'

$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))
require 'gtk3'
require 'cairo'
require 'generador_etiquetas'
require 'gui/aplicacion'

DEMO = File.expand_path('data/demo/codigos_demo.xlsx')
abort "No existe #{DEMO} (ejecuta desde la raíz del proyecto o regenera los fixtures)" unless File.exist?(DEMO)

FALLOS = []
def comprobar(cond, msg)
  if cond
    puts "  OK  #{msg}"
  else
    FALLOS << msg
    puts "  FALLO #{msg}"
  end
end

puts '== Sonda GUI (headful; la ventana no se muestra) =='
Gtk.init

app = GeneradorEtiquetas::Aplicacion.new

# 1. Seleccionar archivo como si el usuario lo hubiera hecho en el diálogo.
chooser = app.instance_variable_get(:@selector_archivo)
chooser.filename = DEMO
comprobar(chooser.filename == DEMO, 'el selector registra el archivo')

# 2. Refresco de hojas. Al asignar filename por código NO se emite 'file-set'
#    (solo ocurre al elegir en el diálogo), de modo que lo ejercitamos a mano,
#    igual que el guard que hay dentro de generar().
selector_hoja = app.instance_variable_get(:@selector_hoja)
app.send(:refrescar_hojas) if selector_hoja.active_text.to_s.include?('1ª')
selector_hoja = app.instance_variable_get(:@selector_hoja)
comprobar(!selector_hoja.active_text.to_s.include?('1ª'),
          "el selector de hoja lista las hojas del archivo (texto=#{selector_hoja.active_text.inspect})")

# 3. Salida a tmp, lote A4 activado y generación en hilo.
salida = Dir.mktmpdir('gui_smoke')
app.instance_variable_get(:@entrada_salida).text = salida
app.instance_variable_get(:@caso_lote).active = true
app.send(:generar)

espera = 0
hasta = 30
while espera < hasta && app.instance_variable_get(:@resultados).size < 6
  Gtk.main_iteration_do(false) while Gtk.events_pending?
  sleep 0.1
  espera += 1
end

resultados = app.instance_variable_get(:@resultados)
comprobar(resultados.size == 6, "generar() rellena 6 resultados (== #{resultados.size})")
comprobar(resultados.count(&:generada?) == 5, '5 están en estado :generada')
comprobar(resultados.any?(&:lote?), 'hay una fila de lote A4')
comprobar(Dir[File.join(salida, '*.pdf')].size == 6, 'se escriben 6 PDFs (5 únicos + lote_A4.pdf)')

# 4. TreeView rellenado y selección de la primera fila.
almacen = app.instance_variable_get(:@almacen)
iter = almacen.iter_first
comprobar(!iter.nil?, 'el TreeView tiene filas')
app.instance_variable_get(:@vista).selection.select_iter(iter)
info = app.instance_variable_get(:@info_previa).text
comprobar(!info.include?('Selecciona un elemento'),
          "actualizar_previa muestra la fila (…#{info[0, 44].inspect}…)")

# 5. Previa offscreen por la misma ruta que 'draw'.
etiqueta = GeneradorEtiquetas::Etiqueta.new(codigo: 'PET-1001', descripcion: 'BATERIA DEMO 001')
layout = GeneradorEtiquetas::LayoutEtiqueta.calcular(
  etiqueta,
  ancho_pt: GeneradorEtiquetas::Dimensiones.pt(100),
  alto_pt: GeneradorEtiquetas::Dimensiones.pt(50)
)
imagen = Cairo::ImageSurface.new(Cairo::FORMAT_RGB24, 300, 180)
cr = Cairo::Context.new(imagen)
GeneradorEtiquetas::PanelEtiqueta.new(layout).dibujar(cr, 300, 180)
oscuros = imagen.data.bytes.count { |b| b.to_i < 120 }
comprobar(oscuros.positive?, "la previa dibuja barras/áreas oscuras (#{oscuros} píxeles)")

puts
puts FALLOS.empty? ? 'PRUEBA DE GUI: CORRECTA' : "PRUEBA DE GUI: #{FALLOS.size} FALLOS"
exit FALLOS.empty? ? 0 : 1