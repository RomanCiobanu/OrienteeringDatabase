class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]

  include ApplicationHelper
  # GET /groups or /groups.json
  def index
    @groups = Group.all
    @index_array = group_index_array(@groups)
  end

  # GET /groups/1 or /groups/1.json
  def show
  end

  # GET /groups/new
  def new
    @group = Group.new
    @competitions = Competition.all
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups or /groups.json
  def create
    params = group_params
    params[:competition_id] = competition_id(params)
    @group = Group.new(params.slice(:name, :clasa, :competition_id))

    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: "Group was successfully created." }
        format.json { render :show, status: :created, location: @group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    respond_to do |format|
      params = group_params
      params[:competition_id] = competition_id(params)

      if @group.update(params.slice(:name, :clasa, :competition_id))
        format.html { redirect_to @group, notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1 or /groups/1.json
  def destroy
    @group.destroy
    respond_to do |format|
      format.html { redirect_to groups_url, notice: "Group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.find(params[:id])
    @competitions = Competition.all
    @index_array = result_index_array(@group.results)
  end

  # Only allow a list of trusted parameters through.
  def group_params
    params.require(:group).permit(:name, :clasa, :rang, :competition_id, :competition_name, :date, :location, :country, :group_id, :distance_type)
  end
end
