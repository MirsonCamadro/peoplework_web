Para correr este proyecto necesitas la API ubicada en: https://github.com/MirsonCamadro/peoplework_api

y el proyecto web ubicado en: https://github.com/MirsonCamadro/peoplework_web

Ambos proyectos estan hechos con ruby 3.0.0, rails 7.0.4 y postgresql

Instrucciones:

Bajar ambos proyectos.

En el API : 
    bundle, luego rails db:create, rails db:migrate, rails db:seed y levantamos el server en el puerto por defecto con rails s
en el WEB :
    bundle, rails db:create, rails db:migrate y levantamos el server en el puerto 3001 con rails s -p 3001

Ingrese 3 datos al seed de la API, solo 1 de ellos es palindromo

    id, branch, description, price
    1, branch1, arbol, 1000
    2, branch2, radar, 2000
    3, branch3, estrella, 3500


PARTE 1

Lo primero que hice fue entender la base de datos. Para eso ocupo www.draw.io para crear un UML por si tiene muchos modelos.

En este caso, como es uno solo empiezo a crear la api con rails con el comando

    rails new product_api --api -d postgresql

la opcion --api para no generar vistas

Luego creo el modelo con el comando

    rails g model Product branch description price:integer

a continuacion reviso la migracion y si esta todo bien migro con

    rails db:migrate

Luego para que la API permita buscar productos en esa base de datos creo un controlador con el comando

    rails g controller Products


PARTE 2

Y creo un metodo para permitir la busqueda en la base de datos y que este compare el query para ver si es un palidromo, o sea, que la query se lea igual de izquierda a derecha o de derecha a izquierda. Para ello lo primero es bajar todas las mayusculas de la query, usando el metodo downcase. Entonces para comparar si es que es un palidromo podria usar el comando
if query.downcase == query.downcase.reverse

creando el metodo en el controlador Products

    def search
        # guardamos la query
        query = params[:query]
        #buscamos esa query en la base de datos Product
        products = Product.where('description LIKE ?', params[:query] + "%" )
    
        #comprobando si es un palidromo y si lo es aplicar el descuento al price
        if query.downcase == query.downcase.reverse
            products.map{|product| product.price *= 0.5}
        end
    
        render json: products
    end

luego hay que definir una ruta para poder hacer la query. En routes.rb agregamos entonces la ruta

    get 'products/search', to: "products#search"

a continuacion levanto el server con rails s y ocupo thunder client (extension de visual studio code para crear requests)

    http://localhost:3000/products/search?query=ingresar_aca_la_query

pero para probar que funcione necesito datos asi que creo datos dummy en el seeds.rb

    Product.create(
        branch: "branch1",
        description: "arbol",
        price: 1000
    )

    Product.create(
        branch: "branch2",
        description: "radar",
        price: 2000
    )

    Product.create(
        branch: "branch3",
        description: "estrella",
        price: 3500
    )

luego rails db:seeds para poblar la base de datos con estos 3 datos
 y hago la consulta para ver si hace el descuento

 http://localhost:3000/products/search?query=arbol
 
     [
      {
        "id": 1,
        "branch": "branch1",
        "description": "arbol",
        "price": 1000,
        "created_at": "2023-03-31T18:04:41.376Z",
        "updated_at": "2023-03-31T18:04:41.376Z"
      }
    ]
    
 http://localhost:3000/products/search?query=radar

     [
      {
        "id": 2,
        "branch": "branch2",
        "description": "radar",
        "price": 1000,
        "created_at": "2023-03-31T18:04:41.399Z",
        "updated_at": "2023-03-31T18:04:41.399Z"
      }
    ]

Por lo que el metodo esta funcionando.

PARTE 3 y 4

cambio el metodo para evaluar si esque es un id el que se consulta (.to_i != 0, ya que cualquier string a .to_i es = 0) o si tiene mas de 3 caracteres

    def search
        # guardamos la query
        query = params[:query]
        # evaluo si es un id o si tiene mas de 3 caracteres para realizar la busqueda en branch o description
        if query.to_i != 0
            products = Product.where(id: query.to_i)
        elsif query.length > 3
            products = Product.where("description LIKE ? OR branch LIKE ?", "%#{query}%", "%#{query}%" )
            #comprobando si es un palidromo y si lo es aplicar el descuento al price
            if query.downcase == query.downcase.reverse
                products.map{|product| product.price *= 0.5}
            end    
        else
            products = []
        end
    
        render json: products
    end


PARTE 5

Creo otro proyecto para consultar la api con rails new product_web -d postgresql. Para simplificar la consulta ocupare la gema httparty

en ProductsController creo el metodo:

    def search
        query = params[:query]
        response = HTTParty.get("http://localhost:3000/products/search/description?query=#{query}")
        @products = JSON.parse(response.body)
    end


y creo la vista que tenga el buscador y una tabla con la respuesta. ocupare bootstrap con cdn en application.html.erb para que la tabla tenga algo de estilo.

    <h1 class="my-3">Busqueda de productos en la API requerida</h1>

    <%= form_tag(products_search_path, method: :get, class:"mt-4") do %>
        <%= label_tag(:query, "Puedes buscar id, marca o descrpcion del producto") %>
        <br>
        <%= text_field_tag(:query) %>
        <%= submit_tag("Buscar") %>
    <% end %>

    <%# validando si hay productos %>

    <% if @products.any? %>
        <h2 class="mt-4">Resultado de la busqueda</h2>

        <div class="table-responsive">
            <table class="table table-dark table-hover text-center mb-5">
                <thead>
                    <tr>
                    <th scope="col">Id</th>
                    <th scope="col">Marca</th>
                    <th scope="col">Descripcion</th>
                    <th scope="col">Precio</th>
                    </tr>
                </thead>
                <% @products.each do |product| %>
                    <tbody>
                        <tr>
                            <td><%= product["id"] %></td>
                            <td><%= product["branch"] %></td>
                            <td><%= product["description"] %></td>
                            <td><%= product["price"] %></td>
                        </tr>
                    </tbody>
                <% end %>
            </table>
        </div>
    <% end %>

a continuacion creo la ruta para acceder a esta vista

  get "/products/search", to: "products#search"

y la agrego al root

    root "products#search"

finalmente levanto el servidor de la API en el puerto por defecto (3000) con rails s
y la web en el puerto 3001 con rails s -p 3001

en el navegador voy a localhost:3001

y ocupo el buscador para hacer las consultas
