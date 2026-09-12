# frozen_string_literal: true

require 'minitest/autorun'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'generador_etiquetas'
require 'tmpdir'

module GeneradorEtiquetas
  class TestEtiqueta < Minitest::Test
    def test_codigo_valido_ascii
      e = Etiqueta.new(codigo: 'PET-1001', descripcion: 'BATERIA')
      assert e.codigo_valido?
    end

    def test_codigo_vacio_invalido
      refute Etiqueta.new(codigo: '  ').codigo_valido?
    end

    def test_codigo_no_ascii_invalido
      refute Etiqueta.new(codigo: 'PET-Ñ001').codigo_valido?
    end

    def test_encoding_code128
      e = Etiqueta.new(codigo: 'PET-1001')
      assert_match(/\A[01]+\z/, e.code128_encoding)
      refute_empty e.code128_encoding
    end

    def test_encoding_invalido_lanza_argument_error
      e = Etiqueta.new(codigo: 'PET-Ñ001')
      assert_raises(ArgumentError) { e.code128_encoding }
    end
  end

  class TestDimensiones < Minitest::Test
    def test_100_mm_es_283_46_pt
      assert_in_delta 283.46, Dimensiones.pt(100), 0.01
    end

    def test_pagina_por_defecto
      ancho, alto = Dimensiones.pagina(ancho_mm: 100, alto_mm: 50)
      assert_in_delta 283.46, ancho, 0.01
      assert_in_delta 141.73, alto, 0.01
    end
  end

  class TestLayout < Minitest::Test
    def setup
      @etiqueta = Etiqueta.new(codigo: 'PET-1001', descripcion: 'BATERIA DEMO 001')
      @layout = LayoutEtiqueta.calcular(
        @etiqueta,
        ancho_pt: Dimensiones.pt(100), alto_pt: Dimensiones.pt(50)
      )
    end

    def test_barras_dentro_de_pagina
      b = @layout.barras
      assert_operator b.x, :>=, Dimensiones::PADDING_PT
      assert_operator b.x + b.ancho, :<=, @layout.pagina_ancho - Dimensiones::PADDING_PT
      refute_empty @layout.encoding
    end

    def test_barras_centradas
      b = @layout.barras
      margen_izq = b.x - Dimensiones::PADDING_PT
      margen_der = (@layout.pagina_ancho - Dimensiones::PADDING_PT) - (b.x + b.ancho)
      assert_in_delta margen_izq, margen_der, 0.1
    end

    def test_descripcion_antes_de_barras
      assert_operator @layout.barras.y, :>, @layout.y_desc_inicio
      assert_operator @layout.y_codigo_inicio, :>, @layout.barras.y + @layout.barras.alto
    end
  end

  class TestLibro < Minitest::Test
    ROOT = File.expand_path('..', __dir__)

    def test_lectura_xlsx_demo
      filas, _ = Libro.cargar(File.join(ROOT, 'data/demo/codigos_demo.xlsx'))
      assert_equal %w[PET-1001 PET-1002 PET-1003 PET-1004 PET-1005], filas.map(&:codigo)
    end

    def test_lectura_csv_demo
      filas, _ = Libro.cargar(File.join(ROOT, 'data/demo/codigos_demo.csv'))
      assert_equal ['PET-1001', 'PET-1001', 'PET-2001', 'PET-2001', 'PET-Ñ001'],
                   filas.map(&:codigo)
    end

    def test_lectura_filas_vacias_omitidas
      filas, _ = Libro.cargar(File.join(ROOT, 'data/demo/codigos_dos_hojas.xlsx'))
      assert_equal %w[PET-1001 PET-1002], filas.map(&:codigo)
    end

    def test_hojas
      hojas = Libro.hojas(File.join(ROOT, 'data/demo/codigos_dos_hojas.xlsx'))
      assert_equal %w[Principal Secundaria], hojas
    end

    def test_archivo_inexistente
      assert_raises(ArgumentError) { Libro.cargar('/no/existe/nada.xlsx') }
    end

    def test_formato_no_soportado
      Dir.mktmpdir do |dir|
        ruta = File.join(dir, 'datos.txt')
        File.write(ruta, 'hola')
        assert_raises(ArgumentError) { Libro.cargar(ruta) }
      end
    end
  end

  class TestMaquina < Minitest::Test
    ROOT = File.expand_path('..', __dir__)

    def setup
      @dir = Dir.mktmpdir('etiquetas_test')
      @maquina = Maquina.new(salida: @dir)
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def test_procesar_demo
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_demo.xlsx'))
      assert_equal 5, reporte.generadas
      assert_equal 0, reporte.duplicadas
      assert_equal 5, Dir[File.join(@dir, '*.pdf')].size
    end

    def test_procesar_problemas
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_con_problemas.xlsx'))
      assert_equal 2, reporte.generadas
      assert_equal 2, reporte.duplicadas
      assert_equal 1, reporte.invalidas
      assert_equal 0, reporte.errores
    end

    def test_cantidad_limita_generacion
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_demo.xlsx'), cantidad: 2)
      assert_equal 2, reporte.generadas
    end

    def test_filtrar
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_demo.xlsx'), filtrar: 'PET-1003')
      assert_equal 1, reporte.generadas
    end

    def test_permitir_duplicados
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_con_problemas.xlsx'),
                                  permitir_duplicados: true)
      assert_equal 4, reporte.generadas
      assert_equal 0, reporte.duplicadas
    end

    def test_hoja_por_nombre
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_dos_hojas.xlsx'),
                                  hoja: 'Secundaria')
      assert_equal 1, reporte.generadas
      assert(File.file?(File.join(@dir, 'P2-0001.pdf')))
    end

    def test_en_progreso_avisa_de_cada_fila
      avances = []
      @maquina.procesar(File.join(ROOT, 'data/demo/codigos_demo.xlsx'),
                        en_progreso: ->(hechas, total) { avances << [hechas, total] })
      assert_equal [1, 2, 3, 4, 5], avances.map(&:first)
      assert_equal [5, 5], avances.last
    end
  end
end