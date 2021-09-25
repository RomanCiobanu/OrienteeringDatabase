class RunnersController < ApplicationController
  before_action :set_runner, only: %i[show edit update destroy]

  # GET /runners or /runners.json
  def index
    @runners = Runner.all

    @index_array = runners_index_array(@runners)
  end

  # GET /runners/1 or /runners/1.json
  def show; end

  # GET /runners/new
  def new
    @runner = Runner.new
    @clubs = Club.all
    @categories = Category.all
  end

  # GET /runners/1/edit
  def edit; end

  # POST /runners or /runners.json
  def create
    params = runner_params
    @runner = Runner.new(params)

    respond_to do |format|
      if @runner.save
        format.html { redirect_to @runner, notice: 'Runner was successfully created.' }
        format.json { render :show, status: :created, location: @runner }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @runner.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /runners/1 or /runners/1.json
  def update
    params = runner_params

    respond_to do |format|
      if @runner.update(params)
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
    @index_array = result_index_array(@runner.results)
  end

  # Only allow a list of trusted parameters through.
  def runner_params
    params.require(:runner).permit(:name, :surname, :gender, :dob, :category_id, :club_id)
  end
end
