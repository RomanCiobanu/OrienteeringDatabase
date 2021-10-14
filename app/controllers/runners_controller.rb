class RunnersController < ApplicationController
  before_action :set_runner, only: %i[show edit update destroy]

  # GET /runners or /runners.json
  def index
    all_runners = Runner.all
    all_runners.all.each do |runner|
      category = get_category(runner)
      runner.category_id = category.id
      runner.save
    end
    @runners =
      if params[:search]
        Runner.where("name LIKE '%#{params[:search]}%'").or(Runner.where("surname LIKE '%#{params[:search]}%'"))
      else
        all_runners
      end.paginate(page: params[:page], per_page: 30)
    @runners = if params[:sort]&.include?('.')
                 @runners.joins(params[:sort].split('.').first.singularize.to_sym).order(params[:sort])
               else
                 @runners.order(params[:sort])
               end
    @index_array = runners_index_array(@runners)
  end

  # GET /runners/1 or /runners/1.json
  def show; end

  # GET /runners/new
  def new
    @runner = Runner.new
    @clubs = Club.all
    @categories = Category.all
    @competitions = Competition.all
  end

  # GET /runners/1/edit
  def edit; end

  # POST /runners or /runners.json
  def create
    params = runner_params

    @runner = Runner.new({
                           name: params[:name],
                           surname: params[:surname],
                           gender: params[:gender],
                           dob: "#{params['dob(1i)']}-#{params['dob(2i)']}-#{params['dob(3i)']}",
                           club_id: params[:club_id]
                         })
    @runner.save

    unless params[:category_id].to_i == 11
      result = Result.new(
        {
          place: params[:place],
          time: params[:hours].to_i * 3600 + params[:minutes].to_i * 60 + params[:seconds].to_i,
          category_id: params[:category_id],
          competition_id: competition_id(params),
          runner_id: @runner.id
        }
      )
      result.save
      @runner.category_id = get_category(@runner)
      @runner.save
    end
    respond_to do |format|
      format.html { redirect_to @runner, notice: 'Runner was successfully created.' }
      format.json { render :show, status: :created, location: @runner }
    end
  end

  # PATCH/PUT /runners/1 or /runners/1.json
  def update
    params = runner_params
    respond_to do |format|
      if @runner.update({
                          name: params[:name],
                          surname: params[:surname],
                          gender: params[:gender],
                          dob: "#{params['dob(1i)']}-#{params['dob(2i)']}-#{params['dob(3i)']}",
                          club_id: params[:club_id]
                        })
        format.html { redirect_to @runner, notice: 'Runner was successfully updated.' }
        format.json { render :show, status: :ok, location: @runner }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @runner.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /runners/1 or /runners/1.json
  def destroy
    @runner.results.each(&:destroy)

    @runner.destroy
    respond_to do |format|
      format.html { redirect_to runners_url, notice: 'Runner was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_runner
    @runner = Runner.find(params[:id])
    @clubs = Club.all
    @categories = Category.all
    @competitions = Competition.all
    @index_array = result_index_array(@runner.results)
    category = get_category(@runner)
    @runner.category_id = category.id
    @runner.save
  end

  # Only allow a list of trusted parameters through.
  def runner_params
    params.require(:runner).permit(
      :name, :surname, :gender, :dob, :category_id, :club_id, :competition_name, :date,
      :location, :country, :group, :distance_type, :rang, :place, :hours, :minutes, :seconds,
      :competition_id
    )
  end

  def competition_id(params)
    return params[:competition_id] unless params[:competition_id] == 'New'

    return default_competition.id if params[:competition_name].blank?

    competition = Competition.new(
      {
        name: params[:competition_name],
        date: params[:date],
        location: params[:location],
        country: params[:country],
        group: params[:group],
        distance_type: params[:distance_type]
      }
    )
    competition.save

    competition.id
  end
end
