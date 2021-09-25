class ResultsController < ApplicationController
  before_action :set_result, only: %i[show edit update destroy]

  # GET /results or /results.json
  def index
    @results = Result.all
    @index_array = result_index_array(@results)
  end

  # GET /results/1 or /results/1.json
  def show; end

  # GET /results/new
  def new
    @result = Result.new
    @competitions = Competition.all
    @runners = Runner.all
    @categories = Category.all
  end

  # GET /results/1/edit
  def edit; end

  # POST /results or /results.json
  def create
    params = result_params
    params[:time] = params[:hours].to_i * 3600 + params[:minutes].to_i * 60 + params[:seconds].to_i

    @result = Result.new(params.except(:hours, :minutes, :seconds))

    respond_to do |format|
      if @result.save
        format.html { redirect_to @result, notice: 'Result was successfully created.' }
        format.json { render :show, status: :created, location: @result }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @result.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /results/1 or /results/1.json
  def update
    params = result_params
    params[:time] = params[:hours].to_i * 3600 + params[:minutes].to_i * 60 + params[:seconds].to_i

    respond_to do |format|
      if @result.update(params.except(:hours, :minutes, :seconds))
        format.html { redirect_to @result, notice: 'Result was successfully updated.' }
        format.json { render :show, status: :ok, location: @result }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @result.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /results/1 or /results/1.json
  def destroy
    @result.destroy
    respond_to do |format|
      format.html { redirect_to results_url, notice: 'Result was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_result
    @result = Result.find(params[:id])
    @index_array = result_index_array([@result])
    @competitions = Competition.all
    @runners = Runner.all
    @categories = Category.all
  end

  # Only allow a list of trusted parameters through.
  def result_params
    params.require(:result).permit(:place, :runner_id, :hours, :minutes, :seconds, :category_id, :competition_id)
  end
end
