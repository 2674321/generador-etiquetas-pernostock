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

def oscuros_offscreen(panel, ancho = 295, alto = 420)
  imagen = Cairo::ImageSurface.new(Cairo::FORMAT_RGB24, ancho, alto)
  cr = Cairo::Context.new(imagen)
  panel.dibujar(cr, ancho, alto, fondo: :gris)
  imagen.data.bytes.count { |b| b.to_i < 120 }
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
comprobar(app.instance_variable_get(:@layout_previo) && app.instance_variable_get(:@hoja_previo).nil?,
          'una fila normal prepara la etiqueta única (sin hoja)')

# 4b. Seleccionar la fila del lote: la previa pasa a ser la hoja A4.
iter_lote = nil
almacen.each { |_m, _p, i| iter_lote = i if i[1] == 'LOTE A4' }
comprobar(!iter_lote.nil?, 'la fila LOTE A4 existe en el TreeView')
app.instance_variable_get(:@vista).selection.select_iter(iter_lote) if iter_lote
comprobar(!app.instance_variable_get(:@info_previa).to_s.include?('Selecciona un elemento'),
          'actualizar_previa muestra la fila LOTE A4')
comprobar(!app.instance_variable_get(:@hoja_previo).nil?,
          'la fila LOTE A4 prepara la vista previa de la hoja')
comprobar(app.instance_variable_get(:@boton_abrir_pdf).sensitive?,
          'abrir el PDF del lote queda habilitado')

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

# 5b. La misma ruta 'draw' aplicada a la hoja A4 del lote (offscreen).
hoja = app.instance_variable_get(:@hoja_previo)
imagen_hoja = Cairo::ImageSurface.new(Cairo::FORMAT_RGB24, 595, 842)
cr_hoja = Cairo::Context.new(imagen_hoja)
hoja.dibujar(cr_hoja, 595, 842)
oscuros_hoja = imagen_hoja.data.bytes.count { |b| b.to_i < 120 }
comprobar(oscuros_hoja.positive?,
          "la previa de hoja dibuja las barras de la cuadrícula (#{oscuros_hoja} píxeles)")

# 5c. Los spinners de margen/separaación del lote están presentes y cableados.
margen_spin = app.instance_variable_get(:@campo_margen_lote)
hueco_spin = app.instance_variable_get(:@campo_hueco_lote)
comprobar(margen_spin && hueco_spin, 'la GUI expone margen/separaación del lote')
margen_spin.value = 30.0
hoja_30 = app.send(:construir_panel_hoja)
comprobar((hoja_30.margen_pt - GeneradorEtiquetas::Dimensiones.pt(30)).abs < 0.5,
          'el margen del lote configurado en la GUI llega a la previa')
margen_spin.value = GeneradorEtiquetas::LoteEtiqueta::MARGEN_PT

# 5d. La previa de hoja pagina: 8 etiquetas de 100×50 en A4 dan 2 páginas.
etiquetas_8 = (1..8).map { |i| GeneradorEtiquetas::Etiqueta.new(codigo: format('PET-20%02d', i)) }
hoja_p1 = GeneradorEtiquetas::PanelHoja.new(
  etiquetas_8,
  ancho_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(100),
  alto_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(50)
)
hoja_p2 = GeneradorEtiquetas::PanelHoja.new(
  etiquetas_8,
  ancho_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(100),
  alto_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(50),
  pagina: 1
)
comprobar(hoja_p1.paginas == 2, 'el lote de 8 etiquetas usa 2 páginas')
oscuros_p2 = oscuros_offscreen(hoja_p2)
comprobar(oscuros_p2.positive?, "la página 2 del lote dibuja sus etiquetas (#{oscuros_p2} px)")

puts
puts FALLOS.empty? ? 'PRUEBA DE GUI: CORRECTA' : "PRUEBA DE GUI: #{FALLOS.size} FALLOS"
exit FALLOS.empty? ? 0 : 1