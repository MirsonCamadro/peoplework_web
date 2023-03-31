class ProductsController < ApplicationController
    def search
        query = params[:query]
        response = HTTParty.get("http://localhost:3000/products/search?query=#{query}")
        @products = JSON.parse(response.body)
    end
end
