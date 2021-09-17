class HomeController < ApplicationController
  def index
    @clubs_count = Club.count
    @runners_count = Runner.count

    runner_one = Runner.order('RANDOM()').first.id
    runner_two = Runner.order('RANDOM()').last.id
    show_wins(runner_one, runner_two)
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
    @runner_one = Runner.find_by(id: one)
    @runner_two = Runner.find_by(id: two)

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
    if params[:path]
      file = Roo::Spreadsheet.open("/home/romanciobanu/results/#{params[:path]}")
      sheet = file.sheet(0)

      @success = []
      @fail    = []

      club = sheet.cell(2, 'B')

      (4..sheet.last_row).each do |index|
        hash = {
          'name' => sheet.cell(index, 'B'),
          'surname' => sheet.cell(index, 'C'),
          'gender' => sheet.cell(index, 'F'),
          'dob(1i)' => sheet.cell(index, 'D').split('/').last.to_i.to_s,
          'dob(2i)' => sheet.cell(index, 'D').split('/')[1].to_i.to_s,
          'dob(3i)' => sheet.cell(index, 'D').split('/').first.to_i.to_s,
          'category_id' => Category.find_by(name: sheet.cell(index, 'E')).id,
          'club_id' => Club.find_by(name: club).id
        }

        @runner = Runner.new(hash)

        if @runner.save
          @success << hash ['name']
        else
          @fail << hash['name']
        end
      end
    end
  end

  def add_competition_file
    if params[:path]
      file = File.read("/home/romanciobanu/results/#{params[:path]}")
      html = Nokogiri::HTML(file)

      competition      = []
      competition_name = html.css('td.s1')[1].text
      competition_date = html.at_css('td.s2').text[/\d{2}.\d{2}.\d{4}/]
      competition_distance_type = html.css('td.s1')[3].text

      @success = []
      @fail    = []

      html.css('tr').each_with_index do |row, index|
        next unless row.text.include?('Categoria de vârstă')

        hash                 = {}
        hash[:name]          = competition_name
        hash[:date]          = competition_date
        hash[:location]      = nil
        hash[:country]       = 'Moldova'
        hash[:distance_type] = competition_distance_type
        hash[:index]         = index
        hash[:group]         = row.at_css('td.s7').text
        hash[:results]       = []

        competition << hash
        addcompetition(hash)
      end

      # competition << { index: html.css('tr').size }

      # headers     = html.at_css("tr[style='height:48px']")
      # header_hash = parse_headers(headers)

      # html.css('tr').each_with_index do |row, index|
      #   unless row.attribute('style').value == 'height:16px' || (row.attribute('style').value == 'height:15px' && row.css('td').size == headers.css('td').size)
      #     next
      #   end

      #   ind = competition.index(competition.detect { |aa| aa[:index] > index }) - 1

      #   hash          = {}
      #   hash[:name]   = row.css('td')[header_hash[:name]].text
      #   hash[:place]  = row.css('td')[header_hash[:place]].text
      #   hash[:result] = row.css('td')[header_hash[:result]].text
      #   time_array    = row.css('td')[header_hash[:result]].text.split(/:|\./)
      #   hash[:time]   = time_array.first.to_i * 3600 + time_array[1].to_i * 60 + time_array.last.to_i
      #   competition[ind][:results] << hash
      # end
    end
  end

  def addcompetition(hash)
    @hash = hash
    competition = {
      'name' => hash[:name],
      'date(1i)' => hash[:date].split('.').last,
      'date(2i)' => hash[:date].split('.')[1],
      'date(3i)' => hash[:date].split('.').first,
      'location' => hash[:location],
      'country' => hash[:country],
      'distance_type' => hash[:distance_type],
      'group' => hash[:group]
    }

    @competition = Competition.new(competition)

    if @competition.save
      @success << hash[:group]
    else
      @fail << hash[:group]
    end
  end

  def parse_headers(html)
    header_hash = {}
    html.css('td').each_with_index do |data, index|
      case data.text
      when /№/
        header_hash[:place] = index
      when /Nume, prenume/
        header_hash[:name] = index
      when /Result/
        header_hash[:result] = index
      end
    end
    header_hash
  end
end
