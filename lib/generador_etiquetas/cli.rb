# frozen_string_literal: true

require 'optparse'

require_relative '../generador_etiquetas'

# Interfaz de consola portable de PernoLabel.
#
#   ruby bin/pernolabel ARCHIVO [OPCIONES]
#
# Todas las rutas se resuelven respecto al directorio de trabajo (portable);
# por defecto la salida se escribe en ./salida.
module GeneradorEtiquetas
  class CLI
    attr_reader :archivo, :opciones

    def self.ejecutar(argv)
      new(argv).correr
    end

    def initialize(argv)
      @archivo = nil
      @opciones = {
        ancho_mm: nil, alto_mm: nil,
        salida: nil, filtrar: nil, cantidad: nil,
        permitir_duplicados: false, quiet: false,
        hoja: 0, listar_hojas: false, lote: false,
        lote_margen_mm: nil, lote_hueco_mm: nil, lote_pagina: nil,
        codigo: LayoutEtiqueta::TIPO_CODE128
      }
      @argv = argv.dup
    end

    def correr
      parsear!
      if @help
        puts uso
        return 0
      end

      unless archivo
        warn uso
        return 1
      end

      if opciones[:listar_hojas]
        GeneradorEtiquetas::Libro.hojas(archivo).each_with_index do |nombre, indice|
          puts "#{indice + 1}: #{nombre}"
        end
        return 0
      end

      maquina = Maquina.new(salida: opciones[:salida],
                            ancho_mm: opciones[:ancho_mm] || Dimensiones::ANCHO_POR_DEFECTO_MM,
                            alto_mm:  opciones[:alto_mm]  || Dimensiones::ALTO_POR_DEFECTO_MM)

      inicio = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      progreso = crear_progreso
      reporte = maquina.procesar(archivo,
                                 filtrar: opciones[:filtrar],
                                 cantidad: opciones[:cantidad],
                                 permitir_duplicados: opciones[:permitir_duplicados],
                                 hoja: opciones[:hoja],
                                 lote: opciones[:lote],
                                 lote_margen_pt: Dimensiones.pt(opciones[:lote_margen_mm]),
                                 lote_hueco_pt: Dimensiones.pt(opciones[:lote_hueco_mm]),
                                 lote_pagina_pt: opciones[:lote_pagina]&.map { |mm| Dimensiones.pt(mm) },
                                 tipo_codigo: opciones[:codigo],
                                 en_progreso: progreso&.callback)
      progreso&.terminar
      transcurrido = Process.clock_gettime(Process::CLOCK_MONOTONIC) - inicio

      mostrar(reporte, transcurrido: transcurrido)
      0
    rescue ArgumentError => e
      warn "Error: #{e.message}"
      1
    end

    private

    # Progreso TTY opcional. Sin terminal (pipas, CI), en modo silencioso o
    # sin la gema, crear_progreso devuelve nil y el CLI se comporta como antes.
    def crear_progreso
      return nil if opciones[:quiet] || !$stdout.tty?

      require 'tty-progressbar'
      ProgressoBarra.new
    rescue LoadError
      nil
    end

    # Reúne el bar (creado a la primera llamada, cuando ya se conoce el total),
    # su callback para la máquina y el cierre.
    class ProgressoBarra
      def initialize
        @ultimo = 0
        @barra = nil
      end

      def callback
        proc do |hechas, total|
          @barra ||= TTY::ProgressBar.new(
            'Generando :bar :percent (:current/:total)',
            total: total, output: $stdout
          )
          avance = hechas - @ultimo
          @ultimo = hechas
          @barra.advance(avance)
        end
      end

      def terminar
        @barra&.finish
      end
    end

    def parsear!
      parser = OptionParser.new do |opts|
        opts.banner = uso
        opts.on('-o', '--salida DIR', 'Directorio de salida (por defecto ./salida)') do |v|
          opciones[:salida] = v
        end
        opts.on('-b', '--buscar TEXTO', 'Solo códigos que contengan TEXTO') do |v|
          opciones[:filtrar] = v
        end
        opts.on('-c', '--cantidad N', Integer, 'Máximo de etiquetas a generar') do |v|
          opciones[:cantidad] = v
        end
        opts.on('--hoja N', 'Hoja a leer (índice como 1 o nombre; por defecto la 1ª)') do |v|
          opciones[:hoja] = v.match?(/\A\d+\z/) ? v.to_i - 1 : v
        end
        opts.on('-l', '--listar-hojas', 'Muestra las hojas del archivo y termina') do
          opciones[:listar_hojas] = true
        end
        opts.on('--todas', 'No omitir códigos duplicados (procesa cada fila)') do
          opciones[:permitir_duplicados] = true
        end
        opts.on('--lote', 'Además genera lote_A4.pdf con las etiquetas en cuadrícula') do
          opciones[:lote] = true
        end

        opts.on('--lote-margen-mm MM', Float,
                'Margen de la hoja del lote en mm (defecto 20)') do |v|
          opciones[:lote_margen_mm] = v
        end

        opts.on('--lote-hueco-mm MM', Float,
                'Separación entre etiquetas del lote en mm (defecto 8)') do |v|
          opciones[:lote_hueco_mm] = v
        end

        opts.on('--lote-pagina ANCHOxALTO',
                'Tamaño de la hoja del lote en mm, p. ej. 210x297 (defecto A4)') do |v|
          ancho, alto = v.split('x').map(&:to_f)
          raise ArgumentError, '--lote-pagina debe ser ANCHOxALTO en mm, p. ej. 210x297' unless ancho&.positive? && alto&.positive?
          opciones[:lote_pagina] = [ancho, alto]
        end
        opts.on('--ancho-mm N', Float, "Ancho de etiqueta en mm (por defecto #{Dimensiones::ANCHO_POR_DEFECTO_MM})") do |v|
          opciones[:ancho_mm] = v
        end
        opts.on('--alto-mm N', Float, "Alto de etiqueta en mm (por defecto #{Dimensiones::ALTO_POR_DEFECTO_MM})") do |v|
          opciones[:alto_mm] = v
        end
        opts.on('--codigo TIPO',
                'Tipo de código: code128 (barras), qr o ambos (defecto code128)') do |v|
          opciones[:codigo] = LayoutEtiqueta.normalizar_tipo(v)
        end

        opts.on('-q', '--quiet', 'Solo resumen') { opciones[:quiet] = true }
        opts.on('-h', '--help', 'Ayuda') { @help = true }
        opts.on('-V', '--version', 'Muestra la versión y termina') do
          puts "PernoLabel #{VERSION}"
          exit 0
        end
      end

      resto = parser.parse(@argv)
      @archivo = resto.first
      opciones[:cantidad] = nil if opciones[:cantidad] && opciones[:cantidad] <= 0
    rescue OptionParser::ParseError => e
      raise ArgumentError, e.message
    end

    def mostrar(reporte, transcurrido: nil)
      unless opciones[:quiet]
        orden = { generada: 'PDF', lote: 'LOTE', duplicada: 'OMIT', invalida: 'INVÁLIDO', error: 'ERROR' }
        reporte.resultados.each do |r|
          etiqueta = orden.fetch(r.estado, r.estado.to_s)
          linea = format('%-9s | %-22s | %s', etiqueta, r.codigo.to_s, r.descripcion.to_s)
          linea += " | #{r.archivo}" if r.generada?
          linea += " | #{r.error}"   if r.error
          puts linea
        end
      end

      puts
      puts reporte.to_s
      puts format('En %.2f s', transcurrido) if !opciones[:quiet] && transcurrido
    end

    def uso
      <<~TXT
        Uso:
          ruby bin/pernolabel ARCHIVO [OPCIONES]

        Genera etiquetas Code128 (PDF) a partir de una hoja de cálculo
        (XLSX/XLS/ODS/CSV). Las columnas de código y descripción se detectan
        automáticamente (encabezados o contenido); no depende de su orden.

        OPCIONES:
          -o, --salida DIR      Directorio de salida (por defecto ./salida)
          -b, --buscar TEXTO    Solo códigos que contengan TEXTO
          -c, --cantidad N      Máximo de etiquetas a generar
              --hoja N          Hoja a leer (número, como 1, o nombre; por defecto la 1ª)
          -l, --listar-hojas    Muestra las hojas del archivo y termina
              --todas           No omitir códigos duplicados
              --ancho-mm N      Ancho de etiqueta en mm (por defecto #{Dimensiones::ANCHO_POR_DEFECTO_MM})
              --alto-mm N       Alto de etiqueta en mm (por defecto #{Dimensiones::ALTO_POR_DEFECTO_MM})
          -q, --quiet           Solo resumen
              --lote            Además genera lote_A4.pdf (cuadrícula de etiquetas)
              --lote-margen-mm MM   Margen de la hoja del lote en mm (defecto 20)
              --lote-hueco-mm MM    Separación entre etiquetas del lote en mm (defecto 8)
              --lote-pagina ANCHOxALTO   Tamaño de hoja del lote en mm, p. ej. 210x297 (defecto A4)
              --codigo TIPO        Tipo de código: code128, qr o ambos (defecto code128)
          -h, --help            Esta ayuda

        Ejemplos:
          ruby bin/pernolabel data/demo/codigos_demo.xlsx
          ruby bin/pernolabel data/demo/codigos_demo.xlsx --salida salida --buscar PET-10
          ruby bin/pernolabel data/demo/codigos_demo.xlsx --listar-hojas
          ruby bin/pernolabel data/demo/codigos_demo.xlsx --hoja Codigos
          ruby bin/pernolabel data/demo/codigos_demo.xlsx --codigo qr
          ruby bin/pernolabel data/demo/codigos_demo.xlsx --codigo ambos --lote
          ruby bin/pernolabel data/demo/codigos_demo.xlsx --lote --lote-margen-mm 10 --lote-hueco-mm 5
          ruby bin/pernolabel data/demo/codigos_demo.xlsx --lote --lote-pagina 150x100
      TXT
    end
  end
end

if $PROGRAM_NAME == __FILE__
  exit GeneradorEtiquetas::CLI.ejecutar(ARGV)
end