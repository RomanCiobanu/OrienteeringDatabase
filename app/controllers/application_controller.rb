class ApplicationController < ActionController::Base
  def runners_index_array(runners)
    runners.map do |runner|
      [
        runner,
        ['runner', "#{runner.name} #{runner.surname}", 'link'],
        ['Category', runner.category.name],
        ['Gender', runner.gender],
        ['Date of Birth', runner.dob],
        ['club', runner.club.name, 'link']
      ]
    end
  end

  def result_index_array(results)
    results.map do |result|
      [
        result,
        ['Place', result.place],
        ['runner', "#{result.runner.name} #{result.runner. surname}", 'link'],
        ['Time', Time.at(result.time).utc.strftime('%H:%M:%S')],
        ['Category', result.category.name],
        ['competition', result.competition.name, 'link']
      ]
    end
  end
end
