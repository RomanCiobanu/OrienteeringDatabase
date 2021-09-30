class ApplicationController < ActionController::Base
  def runners_index_array(runners)
    runners.map do |runner|
      [
        runner,
        ['runner', 'name', "#{runner.name} #{runner.surname}", runner, 'link'],
        ['Category', 'categories.id', get_category(runner).name],
        ['Gender', 'gender', runner.gender],
        ['Date of Birth', 'dob', runner.dob],
        ['club', 'clubs.name', runner.club.name, runner.club, 'link']
      ]
    end
  end

  def result_index_array(results)
    results.map do |result|
      [
        result,
        ['Place', 'place', result.place],
        ['runner', 'runners.name', "#{result.runner.name} #{result.runner. surname}", result.runner, 'link'],
        ['Time', 'time', Time.at(result.time).utc.strftime('%H:%M:%S')],
        ['Category', 'categories.id', result.category.name],
        ['competition', 'competitions.name', result.competition.name, result.competition, 'link']
      ]
    end
  end

  def get_category(runner, from_date = 2.years.ago, to_date = Time.now)
    return Category.find(11) if runner.results.blank?

    Category.find(runner.results.select { |result| (from_date..to_date).include?(result.competition.date) }
      .map(&:category_id).uniq.min)
  end

  def sort_table(elements)
    if params[:sort]&.include?('.')
      if params[:sort]&.include?('count')
        elements.left_joins(:runners)
  .group(:id).order("COUNT(#{params[:sort].split('.').first}.id)")
      else
      elements.joins(params[:sort].split('.').first.singularize.to_sym).order(params[:sort])
      end
    else
      elements.order(params[:sort].to_sym)
    end
  end
end
