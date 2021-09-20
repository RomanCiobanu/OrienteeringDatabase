class ApplicationController < ActionController::Base
  def runners_index_array
    @runners.map do |runner|
      [
        runner,
        ['Name', runner.name],
        ['Surname', runner.surname],
        ['Category', runner.category.name],
        ['Gender', runner.gender],
        ['Date of Birth', runner.dob],
        ['club', runner.club.name, 'link']
      ]
    end
  end
end
