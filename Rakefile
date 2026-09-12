# frozen_string_literal: true

desc 'Prueba headless del core (fixtures demo ficticios)'
task :test do
  ruby 'test/generador_etiquetas_test.rb'
  ruby '_scripts/dev/prueba_core.rb'
end

desc 'CLI: genera etiquetas desde la 1ª hoja del archivo demo'
task :cli, [:archivo] do |_t, args|
  archivo = args[:archivo] || 'data/demo/codigos_demo.xlsx'
  ruby "bin/etiquetas_cli #{archivo}"
end

desc 'GUI (requiere display X11)'
task :gui do
  ruby 'bin/main.rb'
end

task default: :test