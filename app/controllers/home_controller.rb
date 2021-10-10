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

  def set_runners
    show_wins(3, 2)
  end

  def show_wins(one, two)
    @runner_one = Runner.find(one)
    @runner_two = Runner.find(two)
    @index_array1 = result_index_array(@runner_one.results)
    @index_array2 = result_index_array(@runner_two.results)

    @runner_one_wins = 0
    @runner_two_wins = 0
    @tieds           = 0

    competition_ids_one = @runner_one.results.map(&:competition)
    competition_ids_two = @runner_two.results.map(&:competition)

    common_competition = (competition_ids_one & competition_ids_two)

    common_competition.each do |competition|
      first_runner_place  = Result.find_by(competition: competition, runner: @runner_one).place
      second_runner_place = Result.find_by(competition: competition, runner: @runner_two).place

      if first_runner_place == second_runner_place
        @tieds += 1
      elsif first_runner_place < second_runner_place
        @runner_one_wins += 1
      else
        @runner_two_wins += 1
      end
    end
  end

  def add_runners_file
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
    if path[/(xlsx|xlx|ods)$/]
      file = Roo::Spreadsheet.open(path)
      sheet = file.sheet(0)
      parse_excel(sheet)
    else
      file = File.read(path)
      html = Nokogiri::HTML(file)
      return parse_html(html) unless parse_html(html)

      script = html.css('script').detect { |scr| scr.text.include?('var race') }.text
      json   = JSON.parse(script.split(/var \S+ = /).second.remove(';'))
      parse_json(json)
    end
  end

  def add_competition_file
    return unless params[:path]

    path = params[:path].tempfile.path

    @success_competition = []
    @fail_competition    = []
    @success_club = []
    @fail_club    = []
    @success_runner = []
    @fail_runner    = []
    @success_result = []
    @fail_result = []

    parse_html(html)
  end

  def add_competition_sportorg
    @aaa = 'asa'
    return unless params[:path]

    @aaa = 'asa2222'

    path   = params[:path].tempfile.path
    file   = File.read(path)
    html   = Nokogiri::HTML(file)
    script = html.css('script').detect { |scr| scr.text.include?('var race') }.text
    json   = JSON.parse(script.split(/var \S+ = /).second.remove(';'))

    @success_competition = []
    @fail_competition    = []
    @success_club = []
    @fail_club    = []
    @success_runner = []
    @fail_runner    = []
    @success_result = []
    @fail_result = []
    parse_json(json)
  end

  def add_competition(hash)
    @hash = hash
    competition_hash = {
      'name' => hash[:name],
      'date' => hash[:date].to_date.as_json,
      'location' => hash[:location],
      'country' => hash[:country],
      'distance_type' => hash[:distance_type],
      'group' => hash[:group]
    }

    competition = Competition.new(competition_hash)

    if competition.save
      @success_competition << hash[:group]
    else
      @fail_competition << hash[:group]
    end

    competition
  end

  def get_data_hash(data_hash, string)
    crit = case string
           when 'place' then /crt|Nr/
           when 'name' then /Nume(,|) prenume/i
           when 'result' then /Result|Rezultat/
           when 'club' then /Echipa/
           when 'category' then /Cat(eg. sport|)\./
           end

    data_hash[data_hash.keys.detect { |key| key[crit] }]
  end

  def parse_headers(html)
    header_hash = {}
    html.css('td').reject { |td| td.text.blank? }.each_with_index do |data, index|
      case data.text
      when /crt|Nr/
        header_hash[:place] = index
      when /Nume(,|) prenume/i
        header_hash[:name] = index
      when /Result|Rezultat/
        header_hash[:result] = index
      when /Echipa/
        header_hash[:club] = index
      when /Cat(eg. sport|)\./
        header_hash[:category] = index
      end
    end
    header_hash
  end

  def add_club(club)
    return default_club if club.blank?

    club_id = Club.find_by(name: club[:name])

    return club_id if club_id

    new_club = Club.new(club)
    if new_club.save
      @success_club << club
    else
      @fail_club << club
    end

    new_club
  end

  def add_runner_test(hash)
    @aaa = hash
    runner_id = Runner.find_by(hash.slice('name', 'surname'))

    return runner_id if runner_id

    new_runner = Runner.new(hash)

    if new_runner.save
      @success_runner << new_runner
      @asd = 'success'
    else
      @fail_runner << new_runner
      @asd = 'failed'
    end

    new_runner
  end

  def add_result(hash)
    @aaa = hash
    new_result = Result.new(hash)

    if new_result.save
      @success_result << new_result.runner.name
    else
      @fail_result << new_result.runner.name
    end
  end

  def detect_category(hash)
    return Category.find(11) unless hash.values.first

    hash.values.first.gsub!('І', 'I')
    Category.find_by(hash) || Category.find(11)
  end

  def table_array(html)
    colspan = 0
    html.css('td').map do |td|
      size = td['colspan'] ? td['colspan'].to_i : 1
      position = colspan
      colspan += size
      next if td.text.blank?

      [td.text, position]
    end.compact
  end
end
