#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'gui/aplicacion'

GeneradorEtiquetas::Aplicacion.correr(archivo_inicial: ARGV.first)