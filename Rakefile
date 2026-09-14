# frozen_string_literal: true

require 'fileutils'

desc 'Prueba headless del core (fixtures demo ficticios)'
task :test do
  ruby 'test/generador_etiquetas_test.rb'
  ruby '_scripts/dev/prueba_core.rb'
end

desc 'CLI: genera etiquetas desde la 1ª hoja del archivo demo'
task :cli, [:archivo] do |_t, args|
  archivo = args[:archivo] || 'data/demo/codigos_demo.xlsx'
  ruby "bin/pernolabel #{archivo}"
end

desc 'GUI (requiere display X11)'
task :gui do
  ruby 'bin/main.rb'
end

desc 'GUI smoke headful (solo con DISPLAY; prueba el flujo sin mostrar la ventana)'
task :gui_smoke do
  if ENV['DISPLAY'].to_s.empty?
    warn 'Salta gui_smoke: no hay DISPLAY en este entorno.'
  else
    ruby '-Ilib', '_scripts/dev/gui_smoke.rb'
  end
end

desc 'Regenera el icono de PernoLabel (packaging/icons)'
task :icono do
  ruby '_scripts/dev/generar_icono.rb'
end

desc 'Instala el iniciador de escritorio (.desktop + icono en hicolor)'
task :desktop => :icono do
  ruta = File.expand_path(__dir__)
  plantilla = File.read(File.join(ruta, 'packaging/PernoLabel.desktop.in'))

  apps_dir = File.join(ENV['HOME'], '.local/share/applications')
  FileUtils.mkdir_p(apps_dir)
  destino = File.join(apps_dir, 'PernoLabel.desktop')
  File.write(destino, plantilla.gsub('__RUTA__', ruta))

  Dir[File.join(ruta, 'packaging/icons/pernolabel-*.png')].each do |icono|
    tamano = icono[/pernolabel-(\d+)\.png\z/, 1]
    apps_hicolor = File.join(ENV['HOME'], '.local/share/icons/hicolor',
                             "#{tamano}x#{tamano}", 'apps')
    FileUtils.mkdir_p(apps_hicolor)
    FileUtils.cp(icono, File.join(apps_hicolor, 'pernolabel.png'))
  end
  FileUtils.chmod(0o755, File.join(ruta, 'bin/pernolabel_gui'))
  puts "  ✓ Iniciador instalado: #{destino}"
  puts '    Refresca el menú de aplicaciones o usa: gtk-launch PernoLabel'
end

task default: :test