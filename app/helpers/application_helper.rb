module ApplicationHelper
   def add_competition(hash)
    hash[:date] = hash[:date].to_date.as_json

    competition_hash = {
      'name'          => hash[:name],
      'date'          => hash[:date],
      'location'      => hash[:location],
      'country'       => hash[:country],
      'distance_type' => hash[:distance_type],
    }.compact

    competition = Competition.find_by(hash.slice(:name, :date, :distance_type))
    return competition if competition

    competition = Competition.new(competition_hash)

    if competition.save
      @success_competition << competition if @success_competition
    else
      @fail_competition << hash[:name] if @fail_competition
    end

    competition
  end

  def add_group(hash)
    group = Group.find_by(hash)
    return group if group

    new_group = Group.new(hash)
    if new_group.save
      @success_group << new_group if @success_group
    else
      @fail_group << hash[:name] if fail_group
    end

    new_group
  end

  def add_club(hash)
    return default_club if hash.blank?
    club = Club.find_by(name: hash[:name])

    return club if club

    new_club = Club.new(hash)
    if new_club.save
      @success_club << new_club
      @fail_club << new_club
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
                     group_id: default_group.id,
                     category_id: category_id
                   })
      end
    else
      @fail_runner << new_runner
    end

    new_runner
  end

  def add_result(hash)
    return if Result.find_by(hash.slice(:runner_id, :group_id))

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

  def competition_id(params)
    return params[:competition_id] unless params[:competition_id] == 'New'

    return default_competition.id if params[:competition_name].blank?


    add_competition(
      {
        name: params[:competition_name],
        date: params[:date],
        location: params[:location],
        country: params[:country],
        distance_type: params[:distance_type]
      }.compress
    ).id
  end

  def group_id(params, competition_id)
    return default_group if competition_id == default_competition.id

    add_group({
      name: params[:groups],
      competition_id: competition_id
    }).id
  end
end
