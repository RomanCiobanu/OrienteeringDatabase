module HomeHelper
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
          'gender' => group['name'].first,
          'club_id' => add_club(club_hash).id
        }.compact

        @aaa = runner_hash
        new_runner = add_runner_test(runner_hash)
        result = json['results'].detect { |res| res['person_id'] == runner['id'] }
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

      time = sheet.cell(index, 'N') + 1 if sheet.cell(index, 'N')

      if competition.results.new({
        runner_id: runner.id,
        category_id: category_id,
        place: sheet.cell(index, 'O'),
        time: time
      }.compact).save
        @success_result << runner.name
      else
        @fail_result << runner.name
      end
    end
  end

  def parse_html(html)
    competitions              = []
    competition_name          = html.css('tr')[4].at_css('td').text
    competition_date          = html.css('tr').detect { |tr| tr.text.match?(/\d{2}.\d{2}.\d{4}/) }.text[/\d{2}.\d{2}.\d{4}/]
    competition_distance_type = html.css('tr')[7].at_css('td').text

    html.css('tr').each_with_index do |row, index|
      next unless row.text.include?('Categoria de v')

      competition_hash = {
        name: competition_name,
        date: competition_date,
        location: nil,
        country: 'Moldova',
        distance_type: competition_distance_type,
        index: index,
        group: row.css('td').reject { |td| td.text.blank? }.second.text
      }.compact

      competition_hash[:id] = add_competition(competition_hash).id

      competitions << competition_hash
    end

    competitions << { index: html.css('tr').size }

    headers      = html.at_css("tr[style='height:48px']")
    header_array =  table_array(headers)
    # header_hash = parse_headers(headers)

    html.css('tr').each_with_index do |row, index|
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

      # tds = row.css('td').reject { |td| td.text.blank? }

      ind = competitions.index(competitions.detect { |aa| aa[:index] > index }) - 1
      competition = Competition.find(competitions[ind][:id])

      club = add_club({ name: get_data_hash(data_hash, 'club') }.compact)
      name, surname = get_data_hash(data_hash, 'name').split

      runner_hash = {
        'name' => name,
        'surname' => surname,
        'club_id' => club.id,
        'gender' => competition.group.first
      }
      runner = add_runner_test(runner_hash)

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
end
