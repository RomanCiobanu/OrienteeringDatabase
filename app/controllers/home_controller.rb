class HomeController < ApplicationController
  include HomeHelper
  include ApplicationHelper

  def index
    @clubs_count        = Club.count
    @runners_count      = Runner.count
    @competitions_count = Competition.count
    @results_count      = Result.count

    @index_array        = competition_index_array(Competition.order("date desc").limit(10))
  end

  def about
    @array = []
    10.times do
      x = rand(0..9)
      y = rand(0..9)

      while @array.include?([x, y])
        x = rand(0..9)
        y = rand(0..9)
      end
      @array << [x, y]
    end
    @final = Array.new(10) { Array.new(10) }
    10.times do |tr_index|
      10.times do |td_index|
        if @array.include?([tr_index, td_index])
          @final[tr_index][td_index] = 9
          next
        end
        count = 0
        count += 1 if tr_index != 0 && td_index != 0 && @array.include?([tr_index - 1, td_index - 1])
        count += 1 if tr_index != 0 && @array.include?([tr_index - 1, td_index])
        count += 1 if tr_index != 0 && td_index != 10 && @array.include?([tr_index - 1, td_index + 1])
        count += 1 if                   td_index != 0 && @array.include?([tr_index, td_index - 1])
        count += 1 if                   td_index != 10 && @array.include?([tr_index, td_index + 1])
        count += 1 if tr_index != 10 && td_index != 0 && @array.include?([tr_index + 1, td_index - 1])
        count += 1 if tr_index != 10                  && @array.include?([tr_index + 1, td_index])
        count += 1 if tr_index != 10 && td_index != 10 && @array.include?([tr_index + 1, td_index + 1])

        @final[tr_index][td_index] = count
      end
    end
  end

  def compare
    @runners = Runner.all
    @runner = Runner.find(params[:format]) if params[:format]
    show_wins(params[:first_name], params[:second_name]) if params[:first_name] && params[:second_name]
  end
  def merge
    @runners = Runner.all
    @runner = Runner.find(params[:format]) if params[:format]
    return unless params[:first_name] && params[:second_name]
    merge_results(params[:first_name], params[:second_name])

    redirect_to runner_path(Runner.find(params[:first_name]))
  end

  def add_competition_file
    return unless params[:path]

    @success_competition = []
    @fail_competition    = []
    @success_club        = []
    @fail_club           = []
    @success_runner      = []
    @fail_runner         = []
    @success_result      = []
    @fail_result         = []

    path = params[:path].tempfile.path
    parse_data(path)

    @competition_index = competition_index_array(@success_competition)
    @runner_index      = runners_index_array(@success_runner)
    @result_index      = result_index_array(@success_result)
    @club_index         = club_index_array(@success_club)
  end

  def count_rang
    group      = Group.find(params[:format])
    group.rang = get_group_rang(group)
    group.save
    group_competition_date = group.competition.date
    group_results = group.results.sort_by(&:place)
    hash        = get_rang_percents(group.rang)
    winner_time = group_results.first.time
    time_hash   = hash.map { |k,v| [k, v*winner_time/100] }.to_h
    time_hash = case group.clasa
    when "MSRM", "CMSRM" then time_hash.slice(:"3", :"4", :"5", :"6")
    when "Seniori" then time_hash.slice(:"4", :"5", :"6")
    when "Juniori" then time_hash.slice(:"7", :"8", :"9")
    end

    group_results.each do |result|
      time     = result.time
      category = time_hash.detect  { |k,v| v >= time }
      result.category_id = category ? category.first.to_s.to_i : default_category

      result.save
    end


    if ["CMSRM", "MSRM"].include?(group.clasa) && group.rang >=120 &&
      group_results.select {|result| get_category(result.runner, group_competition_date - 1.day).id <= 3}.size > 2
      results         = group_results.first(3)
      res             = results.first
      res.category_id = if group.clasa == "MSRM" &&
        group_results.select {|result| get_category(result.runner, group_competition_date - 1.day).id <= 2}.size > 2
        2
      else
        3
      end

      res.save

      results[1..2].each do |res|
        res.category_id = 3
        res.save
      end
    else
      group_results.select {|result| get_category(result.runner, group_competition_date - 1.day).id <= 3}.each do |res|
        res.category_id = 4
        res.save
      end
    end

    redirect_to group_path(group)
  end
end
