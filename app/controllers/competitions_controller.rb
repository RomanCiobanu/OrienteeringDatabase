class CompetitionsController < ApplicationController
  before_action :set_competition, only: %i[show edit update destroy]

  # GET /competitions or /competitions.json
  def index
    @competitions = Competition.all
    @index_array = competition_index_array(sort_table(@competitions))
  end

  # GET /competitions/1 or /competitions/1.json
  def show
    @competition.rang = @competition.results.map { |result| get_category(result.runner).points }.sum

    @competition.save
  end

  # GET /competitions/new
  def new
    @competition = Competition.new
  end

  # GET /competitions/1/edit
  def edit; end

  # POST /competitions or /competitions.json
  def create
    params = competition_params
    # params[:rang] = competition_params[:result].map do |result|
    #   get_category(result.runner, competition.date - 1.day, competition.date - 2.years).points
    # end.sum

    @competition = Competition.new(params)

    respond_to do |format|
      if @competition.save
        format.html { redirect_to @competition, notice: 'Competition was successfully created.' }
        format.json { render :show, status: :created, location: @competition }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @competition.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /competitions/1 or /competitions/1.json
  def update
    respond_to do |format|
      if @competition.update(competition_params)
        format.html { redirect_to @competition, notice: 'Competition was successfully updated.' }
        format.json { render :show, status: :ok, location: @competition }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @competition.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /competitions/1 or /competitions/1.json
  def destroy
    @competition.results.each(&:destroy)

    @competition.destroy
    respond_to do |format|
      format.html { redirect_to competitions_url, notice: 'Competition was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_competition
    @competition = Competition.find(params[:id])
    @index_array = result_index_array(@competition.results)
  end

  # Only allow a list of trusted parameters through.
  def competition_params
    params.require(:competition).permit(:name, :date, :location, :country, :group, :distance_type, :rang)
  end
end
