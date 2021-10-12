class HomeController < ApplicationController
  include HomeHelper

  def index
    @clubs_count = Club.count
    @runners_count = Runner.count

    # runner_one = Runner.order('RANDOM()').first.id
    # runner_two = Runner.order('RANDOM()').last.id
    # show_wins(runner_one, runner_two)
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

    show_wins(params[:first_name], params[:second_name]) if params[:first_name] && params[:second_name]
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
    @club_indx         = club_index_array(@success_club)
  end

  def count_rang(competition= nil)
    @aaa = "dsa"
    competition = Competition.find(params[:format])

    competition.rang = competition.results.sort_by(&:place).first(12).map { |result| get_category(result.runner).points }.sum

    competition.save

    redirect_to competition_path(competition)
  end
end
