class ApplicationController < ActionController::Base
  helper_method :default_competition

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

  def competition_index_array(competitions)
    competitions.map do |competition|
      [
        competition,
        ['Name', 'name', competition.name],
        ['Date', 'date', competition.date],
        ['Location', 'location', competition.location],
        ['Country', 'country', competition.country],
        ['Group', 'group', competition.group],
        ['Distance Type', 'distance_type', competition.distance_type],
        ['Rang', 'rang', competition.rang]
      ]
    end
  end

  def club_index_array(clubs)
    clubs.map do |club|
      [
        club,
        ['Name', 'name', club.name],
        ['Territory', 'territory', club.territory],
        ['Representative', 'representative', club.representative],
        ['Email', 'email', club.email],
        ['Phone', 'phone', club.phone],
        ['Runners', 'runners.count', club.runners.count]
      ]
    end
  end

  def get_category(runner, date = Time.now)
    return default_category if runner.results.blank?

    Category.find(runner.results.select { |result| ((date - 2.years)..date).cover?(result.competition.date) }
      .map(&:category_id).uniq.min) rescue default_category
  end

  def sort_table(elements)
    return elements unless params[:sort]

    case params[:sort]
    when /count/
      elements.left_joins(:runners).group(:id).order("COUNT(#{params[:sort].split('.').first}.id)")
    when /\./
      elements.joins(params[:sort].split('.').first.singularize.to_sym).order(params[:sort])
    else
      elements.order(params[:sort].to_sym)
    end
  end

  def default_category
    Category.find(10)
  end

  def default_competition
    Competition.find(0)
  end

  def default_club
    Club.find(1)
  end

  def get_competition_rang(competition)
    competition.results.sort_by(&:place).first(12).map { |result| get_category(result.runner, competition.date - 1.day).points }.sum
  end
end
