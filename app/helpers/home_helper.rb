module HomeHelper
  def parse_data(path)
    if path[/(xlsx|xlx|ods)$/]
      file  = Roo::Spreadsheet.open(path)
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
    competition_hash = {
      name:     json.dig('data', 'title'),
      date:     json.dig('data', 'start_datetime').to_date.as_json,
      location: json.dig('data', 'location')
    }

    comp_id = add_competition(competition_hash).id

    json['groups'].each do |group|
      group_hash = {
        name:           group['name'],
        competition_id: comp_id
      }.compact
      group_id = add_group(group_hash).id

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
          'gender' => group['name'].first,
          'club_id' => add_club(club_hash).id
        }.compact

        category_id = convert_category(runner['qual'])
        new_runner  = add_runner(runner_hash, category_id)
        result      = json['results'].detect { |res| res['person_id'] == runner['id'] }
        next if result.nil? || result['place'].to_i < 1

        result_hash = {
          runner_id:   new_runner.id,
          place:       result['place'],
          time:        result['result_msec'] / 1000,
          group_id:    group_id,
          category_id: default_category.id
        }.compact
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
      }.compact

      competition = add_competition(competition_hash)

      group_hash = {
        competition_id: competition.id,
        name: sheet.cell(index, 'J')
      }.compact

      group_id    = add_group(group_hash).id
      category_id = detect_category({ name: sheet.cell(index, 'G') }).id
      time        = sheet.cell(index, 'N') + 1 if sheet.cell(index, 'N')

      result_hash = {
        runner_id:    runner.id,
        category_id: category_id,
        place:       sheet.cell(index, 'O'),
        time:        time,
        group_id:    group_id,
      }.compact

      add_result(result_hash)
    end
  end

  def parse_html(html)
    competition_hash = {
      name:          html.css('tr')[4].at_css('td').text,
      date:          html.css('tr').detect { |tr| tr.text.match?(/\d{2}.\d{2}.\d{4}/) }.text[/\d{2}.\d{2}.\d{4}/],
      distance_type: html.css('tr')[7].at_css('td').text
    }
    competition_id = add_competition(competition_hash).id

    headers = html.at_css("tr[style='height:48px']")
    header_array =  table_array(headers)
    group = default_group

    html.css('tr').each_with_index do |row, index|
      if row.text.include?('Categoria de v')
        group_hash = {
          competition_id: competition_id,
          name:           row.css('td').reject { |td| td.text.blank? }.second.text
        }.compact

        group = add_group(group_hash)
        next
      end

      if row.text.match?(/clas(a|s) dist/i)
        group.clasa = case row.at_css("td.s15").text
        when "MSRM" then "MSRM"
        when "CMSRM" then "CMSRM"
        when /juniori/ then "Juniori"
        else "Seniori"
        end
        group.save
        next
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
        'gender' => group.name.first
      }.compact
      runner = add_runner(runner_hash, detect_category({ name: get_data_hash(data_hash, 'current_category')}).id)

      time_array = get_data_hash(data_hash, 'result').split(/:|\./)

      hash_result = {
        runner_id:   runner.id,
        place:       get_data_hash(data_hash, 'place').to_i,
        time:        time_array.first.to_i * 3600 + time_array[1].to_i * 60 + time_array.last.to_i,
        group_id:    group.id,
        category_id: detect_category({ name: get_data_hash(data_hash, 'category') }).id
      }.compact
      add_result(hash_result)
    end
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

  def merge_results(one, two)
    runner_one = Runner.find(one)
    runner_two = Runner.find(two)

    runner_two.results.each do |result|
      result.runner_id = runner_one.id
      result.save
    end

    runner_two.destroy
  end

  def rang_array
    [
      [1200, { "3": 131, "4": 147, "5": 174, "6": 209, "7": 300, "8": nil, "9": nil }.compact],
      [1100, { "3": 129, "4": 144, "5": 170, "6": 204, "7": 290, "8": nil, "9": nil }.compact],
      [1000, { "3": 126, "4": 141, "5": 166, "6": 199, "7": 280, "8": nil, "9": nil }.compact],
      [800,  { "3": 123, "4": 138, "5": 162, "6": 194, "7": 270, "8": nil, "9": nil }.compact],
      [630,  { "3": 120, "4": 135, "5": 158, "6": 189, "7": 260, "8": nil, "9": nil }.compact],
      [500,  { "3": 117, "4": 132, "5": 154, "6": 184, "7": 250, "8": nil, "9": nil }.compact],
      [400,  { "3": 114, "4": 129, "5": 150, "6": 179, "7": 240, "8": nil, "9": nil }.compact],
      [320,  { "3": 111, "4": 126, "5": 146, "6": 174, "7": 230, "8": nil, "9": nil }.compact],
      [250,  { "3": 108, "4": 123, "5": 142, "6": 170, "7": 220, "8": nil, "9": nil }.compact],
      [200,  { "3": 105, "4": 120, "5": 138, "6": 166, "7": 210, "8": nil, "9": nil }.compact],
      [160,  { "3": 102, "4": 117, "5": 135, "6": 162, "7": 200, "8": 297, "9": nil }.compact],
      [125,  { "3": 100, "4": 114, "5": 132, "6": 158, "7": 190, "8": 297, "9": nil }.compact],
      [100,  { "3": nil, "4": 111, "5": 129, "6": 154, "7": 185, "8": 260, "9": nil }.compact],
      [80,   { "3": nil, "4": 108, "5": 126, "6": 150, "7": 180, "8": 250, "9": nil }.compact],
      [63,   { "3": nil, "4": 105, "5": 123, "6": 146, "7": 175, "8": 240, "9": nil }.compact],
      [50,   { "3": nil, "4": 102, "5": 120, "6": 142, "7": 170, "8": 230, "9": nil }.compact],
      [40,   { "3": nil, "4": 100, "5": 117, "6": 138, "7": 165, "8": 220, "9": 300 }.compact],
      [32,   { "3": nil, "4": nil, "5": 114, "6": 135, "7": 155, "8": 200, "9": 280 }.compact],
      [25,   { "3": nil, "4": nil, "5": 111, "6": 132, "7": 150, "8": 190, "9": 270 }.compact],
      [20,   { "3": nil, "4": nil, "5": 108, "6": 129, "7": 145, "8": 185, "9": 260 }.compact],
      [16,   { "3": nil, "4": nil, "5": 105, "6": 126, "7": 140, "8": 180, "9": 250 }.compact],
      [13,   { "3": nil, "4": nil, "5": 102, "6": 123, "7": 135, "8": 170, "9": 230 }.compact],
      [10,   { "3": nil, "4": nil, "5": 100, "6": 120, "7": 130, "8": 155, "9": 200 }.compact],
      [8,    { "3": nil, "4": nil, "5": nil, "6": 117, "7": 125, "8": 150, "9": 190 }.compact],
      [6,    { "3": nil, "4": nil, "5": nil, "6": 114, "7": 120, "8": 140, "9": 180 }.compact],
      [5,    { "3": nil, "4": nil, "5": nil, "6": 111, "7": 115, "8": 135, "9": 170 }.compact],
      [4,    { "3": nil, "4": nil, "5": nil, "6": 108, "7": 110, "8": 125, "9": 155 }.compact],
      [3,    { "3": nil, "4": nil, "5": nil, "6": 105, "7": 108, "8": 120, "9": 147 }.compact],
      [2,    { "3": nil, "4": nil, "5": nil, "6": 103, "7": 105, "8": 114, "9": 142 }.compact],
      [1,    { "3": nil, "4": nil, "5": nil, "6": 100, "7": nil, "8": 105, "9": 120 }.compact],
      [0.5,  { "3": nil, "4": nil, "5": nil, "6": nil, "7": nil, "8": nil, "9": 105 }.compact]
    ]
  end

  def get_rang_percents(rang)
    rang_array.detect { |row| row.first < rang }.last
  end
end
