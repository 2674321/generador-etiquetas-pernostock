# frozen_string_literal: true

require 'optparse'

require_relative '../generador_etiquetas'

# Interfaz de consola portable.
#
#   ruby bin/etiquetas_cli ARCHIVO [OPCIONES]
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
        permitir_duplicados: false, quiet: false
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

      maquina = Maquina.new(salida: opciones[:salida],
                            ancho_mm: opciones[:ancho_mm] || Dimensiones::ANCHO_POR_DEFECTO_MM,
                            alto_mm:  opciones[:alto_mm]  || Dimensiones::ALTO_POR_DEFECTO_MM)

      reporte = maquina.procesar(archivo,
                                 filtrar: opciones[:filtrar],
                                 cantidad: opciones[:cantidad],
                                 permitir_duplicados: opciones[:permitir_duplicados])

      mostrar(reporte)
      0
    rescue ArgumentError => e
      warn "Error: #{e.message}"
      1
    end

    private

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
        opts.on('--todas', 'No omitir códigos duplicados (procesa cada fila)') do
          opciones[:permitir_duplicados] = true
        end
        opts.on('--ancho-mm N', Float, "Ancho de etiqueta en mm (por defecto #{Dimensiones::ANCHO_POR_DEFECTO_MM})") do |v|
          opciones[:ancho_mm] = v
        end
        opts.on('--alto-mm N', Float, "Alto de etiqueta en mm (por defecto #{Dimensiones::ALTO_POR_DEFECTO_MM})") do |v|
          opciones[:alto_mm] = v
        end
        opts.on('-q', '--quiet', 'Solo resumen') { opciones[:quiet] = true }
        opts.on('-h', '--help', 'Ayuda') { @help = true }
      end

      resto = parser.parse(@argv)
      @archivo = resto.first
      opciones[:cantidad] = nil if opciones[:cantidad] && opciones[:cantidad] <= 0
    rescue OptionParser::ParseError => e
      raise ArgumentError, e.message
    end

    def mostrar(reporte)
      unless opciones[:quiet]
        orden = { generada: 'PDF', duplicada: 'OMIT', invalida: 'INVÁLIDO', error: 'ERROR' }
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
    end

    def uso
      <<~TXT
        Uso:
          ruby bin/etiquetas_cli ARCHIVO [OPCIONES]

        Genera etiquetas Code128 (PDF) a partir de una hoja de cálculo.
        Columna A = código · Columna B = descripción (opcional).

        OPCIONES:
          -o, --salida DIR      Directorio de salida (por defecto ./salida)
          -b, --buscar TEXTO    Solo códigos que contengan TEXTO
          -c, --cantidad N      Máximo de etiquetas a generar
              --todas           No omitir códigos duplicados
              --ancho-mm N      Ancho de etiqueta en mm (por defecto #{Dimensiones::ANCHO_POR_DEFECTO_MM})
              --alto-mm N       Alto de etiqueta en mm (por defecto #{Dimensiones::ALTO_POR_DEFECTO_MM})
          -q, --quiet           Solo resumen
          -h, --help            Esta ayuda

        Ejemplos:
          ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx
          ruby bin/etiquetas_cli data/demo/codigos_demo.xlsx --salida salida --buscar PET-10
      TXT
    end
  end
end

if $PROGRAM_NAME == __FILE__
  exit GeneradorEtiquetas::CLI.ejecutar(ARGV)
end