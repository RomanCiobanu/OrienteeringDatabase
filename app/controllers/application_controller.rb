class ApplicationController < ActionController::Base
  def runners_index_array(runners)
    runners.map do |runner|
      [
        runner,
        ['runner', "#{runner.name} #{runner.surname}", runner, 'link'],
        ['Category', get_category(runner).name],
        ['Gender', runner.gender],
        ['Date of Birth', runner.dob],
        ['club', runner.club.name, runner.club, 'link']
      ]
    end
  end

  def result_index_array(results)
    results.map do |result|
      [
        result,
        ['Place', result.place],
        ['runner', "#{result.runner.name} #{result.runner. surname}", result.runner, 'link'],
        ['Time', Time.at(result.time).utc.strftime('%H:%M:%S')],
        ['Category', result.category.name],
        ['competition', result.competition.name, result.competition, 'link']
      ]
    end
  end

  def get_category(runner, from_date = 2.years.ago, to_date = Time.now)
    return Category.find(11) if runner.results.blank?

    Category.find(runner.results.select { |result| (from_date..to_date).include?(result.competition.date) }
      .map(&:category_id).uniq.min)
  end
end
