require 'shoes'

# Simulación de datos de baterías
baterias = [
  { modelo: 'Modelo1', serie: 'S001', cliente: 'Cliente1' },
  { modelo: 'Modelo2', serie: 'S002', cliente: 'Cliente2' },
  { modelo: 'Modelo3', serie: 'S003', cliente: 'Cliente3' }
]

Shoes.app(title: "Seguimiento de Baterías", width: 400, height: 300) do
  background white
  stack(margin: 10) do
    para "Lista de Baterías", stroke: black, align: "center"
    baterias.each do |bateria|
      flow(margin: 8) do
        para "Modelo: #{bateria[:modelo]}, Serie: #{bateria[:serie]}, Cliente: #{bateria[:cliente]}"
      end
    end
  end
end
