# frozen_string_literal: true

require 'minitest/autorun'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'generador_etiquetas'
require 'cairo'
require 'gui/panel_hoja'
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

  class TestLoteEtiqueta < Minitest::Test
    def test_grarilla_una_etiqueta_a4
      columnas, filas, por_hoja = GeneradorEtiquetas::LoteEtiqueta.grarilla(
        ancho_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ANCHO_PT,
        alto_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ALTO_PT,
        ancho_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(100),
        alto_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(50)
      )
      assert_operator columnas, :>=, 1
      assert_operator filas, :>=, 4, 'cabrían 5 filas de 50 mm en una A4'
      assert_equal columnas * filas, por_hoja
    end

    def test_grarilla_etiqueta_pequena_multiplica_celdas
      columnas, filas, = GeneradorEtiquetas::LoteEtiqueta.grarilla(
        ancho_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ANCHO_PT,
        alto_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ALTO_PT,
        ancho_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(40),
        alto_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(20)
      )
      assert_operator columnas, :>=, 4
      assert_operator filas, :>=, 9
    end

    def test_celda_no_se_sale_de_la_hoja
      ancho = GeneradorEtiquetas::Dimensiones.pt(100)
      alto = GeneradorEtiquetas::Dimensiones.pt(50)
      columnas, filas, _ = GeneradorEtiquetas::LoteEtiqueta.grarilla(
        ancho_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ANCHO_PT,
        alto_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ALTO_PT,
        ancho_etiqueta_pt: ancho, alto_etiqueta_pt: alto
      )
      (0...5).each do |i|
        x, y = GeneradorEtiquetas::LoteEtiqueta.celda(
          i, columnas,
          ancho_etiqueta_pt: ancho, alto_etiqueta_pt: alto
        )
        assert_operator x + ancho, :<=, GeneradorEtiquetas::LoteEtiqueta::A4_ANCHO_PT
        assert_operator y + alto, :<=, GeneradorEtiquetas::LoteEtiqueta::A4_ALTO_PT
      end
    end

    def test_grarilla_responde_al_margen_y_hueco
      ancho = GeneradorEtiquetas::Dimensiones.pt(40)
      alto = GeneradorEtiquetas::Dimensiones.pt(20)
      base = {
        ancho_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ANCHO_PT,
        alto_pagina_pt: GeneradorEtiquetas::LoteEtiqueta::A4_ALTO_PT,
        ancho_etiqueta_pt: ancho, alto_etiqueta_pt: alto
      }
      cols_m20, = GeneradorEtiquetas::LoteEtiqueta.grarilla(**base, margen_pt: 20)
      cols_m120, = GeneradorEtiquetas::LoteEtiqueta.grarilla(**base, margen_pt: 120)
      cols_h5, = GeneradorEtiquetas::LoteEtiqueta.grarilla(**base, hueco_pt: 5)
      cols_h120, = GeneradorEtiquetas::LoteEtiqueta.grarilla(**base, hueco_pt: 120)
      assert_operator cols_m20, :>, cols_m120, 'un margen mayor reduce las columnas'
      assert_operator cols_h5, :>, cols_h120, 'un hueco mayor reduce las columnas'
    end

    def test_generar_lote_a4
      etiquetas = %w[PET-1001 PET-1002 PET-1003 PET-1004 PET-1005].map do |codigo|
        GeneradorEtiquetas::Etiqueta.new(codigo: codigo, descripcion: "DESC #{codigo}")
      end
      Dir.mktmpdir('lote_test') do |dir|
        ruta = File.join(dir, 'lote_A4.pdf')
        columnas, filas, hojas = GeneradorEtiquetas::LoteEtiqueta.generar(
          etiquetas, ruta,
          ancho_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(100),
          alto_etiqueta_pt: GeneradorEtiquetas::Dimensiones.pt(50)
        )
        assert_equal 1, hojas
        assert_operator columnas, :>=, 1
        assert_operator filas, :>=, 5
        ancho_firma = %r{/MediaBox \[\d+ \d+ ([0-9.]+)(?: |\])}.match(File.binread(ruta))&.captures&.first
        assert_in_delta GeneradorEtiquetas::Dimensiones.pt(210), ancho_firma.to_f, 0.1,
                        'el lote es A4 (210 mm de ancho)'
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

    def test_lote_con_margen_personalizado
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_demo.xlsx'),
                                  lote: true, lote_margen_pt: Dimensiones.pt(10),
                                  lote_hueco_pt: Dimensiones.pt(3))
      assert_equal 1, reporte.lotes
      assert File.file?(File.join(@dir, LoteEtiqueta::NOMBRE_ARCHIVO)),
             'el lote se crea con margen/hueco a medida'
      binario = File.binread(File.join(@dir, LoteEtiqueta::NOMBRE_ARCHIVO))
      assert_match %r{/MediaBox \[\d+ \d+ [0-9.]+\s+[0-9.]+\]}, binario
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

    def test_lote_con_pagina_personalizada
      reporte = @maquina.procesar(File.join(ROOT, 'data/demo/codigos_demo.xlsx'),
                                  lote: true, lote_pagina_pt: [Dimensiones.pt(150), Dimensiones.pt(100)])
      assert_equal 1, reporte.lotes
      lote = reporte.resultados.find(&:lote?)
      assert_includes lote.descripcion, '150.0×100.0 mm'
      binario = File.binread(lote.archivo)
      m = %r{/MediaBox \[\d+ \d+ ([0-9.]+) ([0-9.]+)\]}.match(binario)
      assert_in_delta Dimensiones.pt(150), m[1].to_f, 0.1
      assert_in_delta Dimensiones.pt(100), m[2].to_f, 0.1
    end
  end

  class TestLotePaginas < Minitest::Test
    GA = GeneradorEtiquetas
    BASE = {
      ancho_pagina_pt: LoteEtiqueta::A4_ANCHO_PT, alto_pagina_pt: LoteEtiqueta::A4_ALTO_PT,
      ancho_etiqueta_pt: Dimensiones.pt(100), alto_etiqueta_pt: Dimensiones.pt(50)
    }.freeze

    def test_paginas_segun_el_numero_total
      assert_equal 1, LoteEtiqueta.paginas(5, **BASE)
      assert_equal 2, LoteEtiqueta.paginas(8, **BASE)
      assert_equal 1, LoteEtiqueta.paginas(0, **BASE), 'sin etiquetas hay 1 hoja limpia'
    end

    def test_por_hoja_coincide_con_grarilla
      assert_equal LoteEtiqueta.grarilla(**BASE)[2], LoteEtiqueta.por_hoja(**BASE)
    end
  end

  class TestPanelHoja < Minitest::Test
    GA = GeneradorEtiquetas

    def panel(etiquetas, pagina: 0)
      PanelHoja.new(etiquetas,
                    ancho_etiqueta_pt: GA::Dimensiones.pt(100),
                    alto_etiqueta_pt: GA::Dimensiones.pt(50),
                    pagina: pagina)
    end

    def etiquetas(n)
      (1..n).map { |i| GA::Etiqueta.new(codigo: format('PET-10%02d', i), descripcion: "D#{i}") }
    end

    def oscuros(panel)
      imagen = Cairo::ImageSurface.new(Cairo::FORMAT_RGB24, 200, 280)
      cr = Cairo::Context.new(imagen)
      panel.dibujar(cr, 200, 280, fondo: :gris)
      imagen.data.bytes.count { |b| b.to_i < 120 }
    end

    def test_multipagina
      hoja = panel(etiquetas(8))
      assert_equal 2, hoja.paginas
      assert_equal 5, hoja.etiquetas_pagina.size, 'la página 1 muestra las 5 primeras'
      hoja2 = panel(etiquetas(8), pagina: 1)
      assert_equal 3, hoja2.etiquetas_pagina.size, 'la página 2 muestra las 3 restantes'
    end

    def test_pagina_vacia_no_dibuja_contenido
      hoja_fuera = panel(etiquetas(5), pagina: 3)
      assert_empty hoja_fuera.etiquetas_pagina
      assert_equal 0, oscuros(hoja_fuera), 'una página sin etiquetas queda en blanco'
    end

    def test_paginas_dibujan_barras
      [0, 1].each do |pagina|
        hoja = panel(etiquetas(8), pagina: pagina)
        assert_operator oscuros(hoja), :>, 0, "la página #{pagina + 1} dibuja contenido"
      end
    end
  end
end