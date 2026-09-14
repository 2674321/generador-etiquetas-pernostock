#!/usr/bin/env ruby
# frozen_string_literal: true

# Captura de pantalla de la GUI para el README (solo entorno DEV headful).
#
# Uso (el script mantiene la ventana viva hasta que se le mande terminar):
#   ruby _scripts/dev/screenshot_gui.rb &   # imprime "LISTO" cuando puede capturar
#   import -window "$(xdotool search --name PernoLabel | head -1)" docs/screenshot-gui.png
#   kill %1
#
# Abre la ventana con el demo cargado, genera las etiquetas y selecciona la
# primera fila para que la vista previa se dibuje en el panel derecho.

require 'gtk3'
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'gui/aplicacion'

ROOT = File.expand_path('../..', __dir__)
DEMO = File.join(ROOT, 'data/demo/codigos_demo.csv')
SALIDA = File.join(ROOT, 'tmp/screenshot/salida')

abort "Falta #{DEMO}" unless File.exist?(DEMO)
abort 'No hay DISPLAY (deja X11 activo)' if ENV['DISPLAY'].to_s.empty?

Gtk.init
app = GeneradorEtiquetas::Aplicacion.new(archivo_inicial: DEMO)
ventana = app.ventana
ventana.show_all
ventana.present
60.times { Gtk.main_iteration_do(false) }
sleep 0.4

entrada_salida = app.instance_variable_get(:@entrada_salida)
entrada_salida.text = SALIDA
10.times { Gtk.main_iteration_do(false) }

app.send(:generar)
60.times { Gtk.main_iteration_do(false) }
sleep 0.4

vista = app.instance_variable_get(:@vista)
vista.selection.select_path(Gtk::TreePath.new('0'))
40.times { Gtk.main_iteration_do(false) }
sleep 0.4
ventana.window.display.flush
20.times { Gtk.main_iteration_do(false) }
sleep 0.5

puts 'LISTO'
STDOUT.flush
loop do
  Gtk.main_iteration_do(true)
  sleep 0.1
rescue StandardError
  sleep 0.2
end