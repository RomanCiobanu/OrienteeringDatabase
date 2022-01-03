# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
categories = [{"id":1,"name":"MISRM","full_name":"Maestru Internaţional al Sportului","points":300.0},{"id":2,"name":"MSRM","full_name":"Maestru al Sportului","points":100.0},{"id":3,"name":"CMSRM","full_name":"Candidat în Maeștri ai Sportului","points":30.0},{"id":4,"name":"I","full_name":"Categoria I","points":10.0},{"id":5,"name":"II","full_name":"Categoria II","points":4.0},{"id":6,"name":"III","full_name":"Categoria III","points":2.0},{"id":7,"name":"I j","full_name":"Categoria I juniori","points":1.0},{"id":8,"name":"II j","full_name":"Categoria II juniori","points":0.5},{"id":9,"name":"III j","full_name":"Categoria III juniori","points":0.3},{"id":10,"name":"f/c","full_name":"Fara Categorie","points":0.0}]

categories.each do |category|
  Category.create(category)
end

Competition.create("id": 0,"name": "No Competition","date": "2021-08-01")
Club.create("id": 0, "name": "Individual")
User.create("email": "roma.ciobanu@gmail.com", "password": "Sport5Roma" )
Group.create("id": 0, "name": "No Group", "competition_id": 0)
