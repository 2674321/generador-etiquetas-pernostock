#!/usr/bin/env ruby
# frozen_string_literal: true

# Valida el feedback en vivo con un documento GRANDE sintético (2500 filas):
#   - el spinner arranca, la barra avanza en vivo y la UI se repinta
#   - al terminar, la interfaz vuelve a su estado normal con todos los resultados
# Uso: DISPLAY=:0 ruby -Ilib _scripts/dev/probe_progreso.rb

require 'fileutils'
require 'tmpdir'
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'gtk3'
require 'generador_etiquetas'
require 'gui/aplicacion'

FILAS = 2500
directorio = Dir.mktmpdir('pernolabel_probe')
grande = File.join(directorio, 'grande.csv')
salida = File.join(directorio, 'salida')

File.open(grande, 'w') do |f|
  f.puts('Código,Descripción')
  (1..FILAS).each { |i| f.puts(format('PET-%04d,Batería sintética %04d', i, i)) }
end

Gtk.init
app = GeneradorEtiquetas::Aplicacion.new
app.instance_variable_get(:@selector_archivo).filename = grande
app.instance_variable_get(:@entrada_salida).text = salida

muestras = []
marcar_parar = false
muestreador = Thread.new do
  until marcar_parar
    spinner = app.instance_variable_get(:@spinner)
    barra = app.instance_variable_get(:@barra_progreso)
    muestras << {
      girando: spinner.active?,
      fraction: barra.fraction,
      texto: barra.text.to_s
    }
    sleep 0.05
  end
end

inicio = Process.clock_gettime(Process::CLOCK_MONOTONIC)
app.send(:generar)

espera = 0
while espera < 6000 && app.instance_variable_get(:@resultados).size < FILAS
  Gtk.main_iteration_do(false) while Gtk.events_pending?
  sleep 0.02
  espera += 1
end
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - inicio
marcar_parar = true
muestreador.join(2)

resultados = app.instance_variable_get(:@resultados)
fractions = muestras.map { |m| m[:fraction] }
girando = muestras.any? { |m| m[:girando] }
texto_vivo = muestras.any? { |m| m[:texto].include?('de 2500') }
barra_uso = fractions.select { |v| v.positive? && v < 1.0 }.size

puts "filas=#{resultados.size} generadas=#{resultados.count(&:generada?)}"
puts "tiempo=#{elapsed.round(2)}s muestras=#{muestras.size}"
puts "spinner_visto=#{girando} fracciones_intermedias=#{barra_uso} texto_n_de_m=#{texto_vivo}"
fin = resultados.all? { |r| r.estado == :generada } && resultados.size == FILAS &&
      app.instance_variable_get(:@boton_generar).sensitive?
puts fin ? 'PROBE PROGRESO: CORRECTA' : 'PROBE PROGRESO: CON CUIDADO'

primer_pdf = File.join(salida, 'PET-0001.pdf')
puts "primer_pdf=#{File.exist?(primer_pdf)}"
exit 0