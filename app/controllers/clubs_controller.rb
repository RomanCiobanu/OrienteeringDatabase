class ClubsController < ApplicationController
  before_action :set_club, only: %i[show edit update destroy]

  # GET /clubs or /clubs.json
  def index
    @clubs = Club.all
    @index_array = club_index_array(sort_table(@clubs))
  end

  # GET /clubs/1 or /clubs/1.json
  def show; end

  # GET /clubs/new
  def new
    @club = Club.new
  end

  # GET /clubs/1/edit
  def edit; end

  # POST /clubs or /clubs.json
  def create
    @club = Club.new(club_params)

    respond_to do |format|
      if @club.save
        format.html { redirect_to @club, notice: 'Club was successfully created.' }
        format.json { render :show, status: :created, location: @club }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @club.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clubs/1 or /clubs/1.json
  def update
    respond_to do |format|
      if @club.update(club_params)
        format.html { redirect_to @club, notice: 'Club was successfully updated.' }
        format.json { render :show, status: :ok, location: @club }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @club.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clubs/1 or /clubs/1.json
  def destroy
    @club.runners.each do |runner|
      runner.club.id = 1
      runner.save
    end

    @club.destroy
    respond_to do |format|
      format.html { redirect_to clubs_url, notice: 'Club was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_club
    @club = Club.find(params[:id])
    @index_array = runners_index_array(@club.runners)
  end

  # Only allow a list of trusted parameters through.
  def club_params
    params.require(:club).permit(:name, :territory, :representative, :email, :phone)
  end

  def index_array
    sort_table(@clubs)
  end
end
