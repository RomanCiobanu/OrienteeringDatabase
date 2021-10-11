module HomeHelper
  def parse_data(path)
    if path[/(xlsx|xlx|ods)$/]
      file = Roo::Spreadsheet.open(path)
      sheet = file.sheet(0)
      parse_excel(sheet)
    else
      file = File.read(path)
      html = Nokogiri::HTML(file)
      return parse_html(html) unless html.at_css('script')

      script = html.css('script').detect { |scr| scr.text.include?('var race') }.text
      json   = JSON.parse(script.split(/var \S+ = /).second.remove(';'))
      parse_json(json)
    end
  end

  def parse_json(json)
    competition_name = json.dig('data', 'title')
    competition_date = json.dig('data', 'start_datetime').to_date.as_json
    competition_location = json.dig('data', 'location')

    json['groups'].each do |group|
      competition_hash = {
        name: competition_name,
        date: competition_date,
        location: competition_location,
        country: 'Moldova',
        distance_type: 'default',
        group: group['name']
      }.compact

      competition_id = add_competition(competition_hash).id

      json['persons'].select { |pers| pers['group_id'] == group['id'] }.each do |runner|
        club = json['organizations'].detect { |org| org['id'] == runner['organization_id'] }
        club_hash = {
          name: club['name'],
          representative: club['contact'],
          territory: club['region']
        }.compact

        runner_hash = {
          'name' => runner['surname'],
          'surname' => runner['name'],
          'dob' => runner['birth_date'],
          'gender' => 'W45'.first,
          'club_id' => add_club(club_hash).id
        }.compact

        category_id = convert_category(runner['qual'])
        new_runner  = add_runner(runner_hash, category_id)
        result      = json['results'].detect { |res| res['person_id'] == runner['id'] }
        next if result['place'].to_i < 1

        result_hash = {
          runner_id: new_runner.id,
          place: result['place'],
          time: result['result_msec'] / 1000,
          competition_id: competition_id,
          category_id: default_category.id

        }
        add_result(result_hash)
      end
    end
  end

  def parse_excel(sheet)
    club_data = {
      name: sheet.cell(2, 'B'),
      territory: sheet.cell(2, 'C'),
      representative: sheet.cell(2, 'D'),
      email: sheet.cell(2, 'F'),
      phone: sheet.cell(2, 'H')
    }.compact

    club = add_club(club_data)

    (5..sheet.last_row).each do |index|
      next if sheet.cell(index, 'B').blank?

      runner_hash = {
        'name' => sheet.cell(index, 'B'),
        'surname' => sheet.cell(index, 'C'),
        'gender' => sheet.cell(index, 'F'),
        'dob' => sheet.cell(index, 'D').to_date.as_json,
        # 'category_id' => Category.find_by(name: sheet.cell(index, 'E')).id || 48,
        'club_id' => club.id
      }.compact

      runner = add_runner(runner_hash)

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

      time = sheet.cell(index, 'N') + 1 if sheet.cell(index, 'N')

      if competition.results.new({
        runner_id: runner.id,
        category_id: category_id,
        place: sheet.cell(index, 'O'),
        time: time
      }.compact).save
        @success_result << runner
      else
        @fail_result << runner
      end
    end
  end

  def parse_html(html)
    competition_name          = html.css('tr')[4].at_css('td').text
    competition_date          = html.css('tr').detect { |tr| tr.text.match?(/\d{2}.\d{2}.\d{4}/) }
                                    .text[/\d{2}.\d{2}.\d{4}/]
    competition_distance_type = html.css('tr')[7].at_css('td').text
    headers = html.at_css("tr[style='height:48px']")
    header_array =  table_array(headers)
    competition = ''

    html.css('tr').each_with_index do |row, index|
      if row.text.include?('Categoria de v')
        competition_hash = {
          name: competition_name,
          date: competition_date,
          location: nil,
          country: 'Moldova',
          distance_type: competition_distance_type,
          index: index,
          group: row.css('td').reject { |td| td.text.blank? }.second.text
        }.compact

        competition = add_competition(competition_hash)
      end

      unless row.attribute('style').value == 'height:16px' ||
             (row.attribute('style').value == 'height:15px' && row.at_css('td').text.to_i != 0)
        next
      end

      runner_array = table_array(row)
      data_hash = {}

      runner_array.each do |a|
        crit = header_array.detect { |el| el.last == a.last }.first
        data_hash[crit] = a.first
      end

      club = add_club({ name: get_data_hash(data_hash, 'club') }.compact)
      name, surname = get_data_hash(data_hash, 'name').split

      runner_hash = {
        'name' => name,
        'surname' => surname,
        'club_id' => club.id,
        'gender' => competition.group.first
      }

      runner = add_runner(runner_hash, detect_category({ name: get_data_hash(data_hash, 'current_category') }).id)

      hash_result = {}
      hash_result[:runner_id] = runner.id
      hash_result[:place] = get_data_hash(data_hash, 'place').to_i
      time_array = get_data_hash(data_hash, 'result').split(/:|\./)
      hash_result[:time] = time_array.first.to_i * 3600 + time_array[1].to_i * 60 + time_array.last.to_i
      hash_result[:competition_id] = competition.id
      hash_result[:category_id] = detect_category({ name: get_data_hash(data_hash, 'category') }).id
      add_result(hash_result)
    end
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
      @success_competition << competition
    else
      @fail_competition << competition
    end

    competition
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

  def add_runner(hash, category_id = nil)
    runner_id = Runner.find_by(hash.slice('name', 'surname'))

    return runner_id if runner_id

    new_runner = Runner.new(hash)

    if new_runner.save
      @success_runner << new_runner

      if category_id && category_id != default_category.id
        add_result({
                     runner_id: new_runner.id,
                     competition_id: default_competition.id,
                     category_id: category_id
                   })
      end
    else
      @fail_runner << new_runner
    end

    new_runner
  end

  def add_result(hash)
    new_result = Result.new(hash)

    if new_result.save
      @success_result << new_result
    else
      @fail_result << new_result
    end
  end

  def get_data_hash(data_hash, string)
    crit = case string
           when 'place' then /crt|Nr/
           when 'name' then /Nume(,|) prenume/i
           when 'result' then /Result|Rezultat/
           when 'club' then /Echipa/
           when 'category' then /Cat(eg. îndepl|)\./
           when 'current_category' then /Categ. sport./
           end

    data_hash[data_hash.keys.detect { |key| key[crit] }]
  end

  def detect_category(hash)
    return default_category unless hash.values.first

    hash.values.first.gsub!('І', 'I')
    Category.find_by(hash) || default_category
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

  def convert_category(category_id)
    case category_id
    when 9 then 1
    when 8 then 2
    when 7 then 3
    when 6 then 6
    when 5 then 5
    when 4 then 4
    when 3 then 9
    when 2 then 8
    when 1 then 7
    when 0 then 10
    end
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
end
