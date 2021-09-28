class HomeController < ApplicationController
  def index
    # @clubs_count = Club.count
    # @runners_count = Runner.count

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

    file = Roo::Spreadsheet.open("/home/romanciobanu/results/#{params[:path]}")
    sheet = file.sheet(0)

    @success_competition = []
    @fail_competition    = []
    @success_club        = []
    @fail_club           = []
    @success_runner      = []
    @fail_runner         = []
    @success_result      = []
    @fail_result         = []

    club_data = {
      name: sheet.cell(2, 'B'),
      territory: sheet.cell(2, 'C'),
      representative: sheet.cell(2, 'D'),
      email: sheet.cell(2, 'F'),
      phone: sheet.cell(2, 'H')
    }.compact

    club = add_club(club_data)

    (5..sheet.last_row).each do |index|
      runner_hash = {
        'name' => sheet.cell(index, 'B'),
        'surname' => sheet.cell(index, 'C'),
        'gender' => sheet.cell(index, 'F'),
        'dob(1i)' => sheet.cell(index, 'D').split('.').last.to_i.to_s,
        'dob(2i)' => sheet.cell(index, 'D').split('.')[1].to_i.to_s,
        'dob(3i)' => sheet.cell(index, 'D').split('.').first.to_i.to_s,
        # 'category_id' => Category.find_by(name: sheet.cell(index, 'E')).id || 48,
        'club_id' => club.id || 11
      }.compact

      runner = add_runner_test(runner_hash)

      competition_hash = {
        name: sheet.cell(index, 'I'),
        date: sheet.cell(index, 'H'),
        location: sheet.cell(index, 'L'),
        country: sheet.cell(index, 'M'),
        distance_type: sheet.cell(index, 'K'),
        group: sheet.cell(index, 'J')
      }
      competition = add_competition(competition_hash)

      category_id = detect_category({ name: sheet.cell(index, 'G') }).id

      if competition.results.new({ runner_id: runner.id, category_id: category_id }).save
        @success_result << runner.name
      else
        @fail_result << runner.name
      end
    end
  end

  def add_competition_file
    return unless params[:path]

    file = File.read("/home/romanciobanu/results/#{params[:path]}")
    html = Nokogiri::HTML(file)

    competitions              = []
    competition_name          = html.css('td.s1')[1].text
    competition_date          = html.at_css('td.s2').text[/\d{2}.\d{2}.\d{4}/]
    competition_distance_type = html.css('td.s1')[3].text

    @success_competition = []
    @fail_competition    = []
    @success_club = []
    @fail_club    = []
    @success_runner = []
    @fail_runner    = []
    @success_result = []
    @fail_result = []
    clubs = []

    html.css('tr').each_with_index do |row, index|
      next unless row.text.include?('Categoria de vârstă')

      competition_hash = {
        name:           competition_name,
        date:           competition_date,
        location:       nil,
        country:        'Moldova',
        distance_type:  competition_distance_type,
        index:          index,
        group:          row.at_css('td.s7').text
      }.compact

      competition_hash[:id] = add_competition(competition_hash).id

      competitions << competition_hash
    end

    competitions << { index: html.css('tr').size }

    headers     = html.at_css("tr[style='height:48px']")
    header_hash = parse_headers(headers)

    html.css('tr').each_with_index do |row, index|
      unless row.attribute('style').value == 'height:16px' ||
             (row.attribute('style').value == 'height:15px' && row.at_css('td').text == '1')
        next
      end

      ind = competitions.index(competitions.detect { |aa| aa[:index] > index }) - 1
      competition = Competition.find(competitions[ind][:id])

      club = add_club({ name: row.css('td')[header_hash[:club]].text }.compact)
      name, surname = row.css('td')[header_hash[:name]].text.split

      runner_hash = {
        'name'    => name,
        'surname' => surname,
        'club_id' => club.id,
        'gender'  => competition.group.first
      }
      runner = add_runner_test(runner_hash)

      hash_result = {}
      hash_result[:runner_id] = runner.id
      hash_result[:place] = row.css('td')[header_hash[:place]].text.to_i
      time_array = row.css('td')[header_hash[:result]].text.split(/:|\./)
      hash_result[:time] = time_array.first.to_i * 3600 + time_array[1].to_i * 60 + time_array.last.to_i
      hash_result[:competition_id] = competition.id
      hash_result[:category_id] = detect_category({ name: row.css('td')[header_hash[:category]].text.gsub("І", "I") }).id
      add_result(hash_result)
    end
  end

  def add_competition(hash)
    @hash = hash
    competition_hash = {
      'name' => hash[:name],
      'date(1i)' => hash[:date].to_date.year.to_s,
      'date(2i)' => hash[:date].to_date.month.to_s,
      'date(3i)' => hash[:date].to_date.day.to_s,
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

  def parse_headers(html)
    header_hash = {}
    html.css('td').each_with_index do |data, index|
      case data.text
      when /crt/
        header_hash[:place] = index
      when /Nume, prenume/
        header_hash[:name] = index
      when /Result/
        header_hash[:result] = index
      when /Echipa/
        header_hash[:club] = index
      when /Cat\./
        header_hash[:category] = index
      end
    end
    header_hash
  end

  def add_club(club)
    return if club.blank?

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

  def add_runner(runner, club, gender, category = nil)
    name, surname = runner.split
    runner_id = Runner.find_by(name: name, surname: surname)
    return runner_id if runner_id

    club_id     = club ? club.id : 48
    category_id = category ? category.id : 11

    new_runner = Runner.new({ name: name, surname: surname, club_id: club_id, category_id: category_id, gender: gender })
    if new_runner.save
      @success_runner << new_runner
    else
      @fail_runner << new_runner
    end

    new_runner
  end

  def add_runner_test(hash)
    runner_id = Runner.find_by(hash.slice('name', 'surname'))
    return runner_id if runner_id

    new_runner = Runner.new(hash)

    if new_runner.save
      @success_runner << new_runner
    else
      @fail_runner << new_runner
    end

    new_runner
  end

  def add_result(hash)
    new_result = Result.new(hash)

    if new_result.save
      @success_result << new_result.runner.name
    else
      @fail_result << new_result.runner.name
    end
  end

  def detect_category(hash)
    Category.find_by(hash) || Category.find(11)
  end
end
