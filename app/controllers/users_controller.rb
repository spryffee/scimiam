class UsersController < ApplicationController
  before_action :authorize
  before_action :set_user, only: %i[show]
  before_action :set_accesses, only: %i[show]

  def index
    search_params = params.permit(:format, :page, q: [:displayname_cont, :s])
    @q = User.select(:id, :displayname, :work_email_address).where(is_active: true).order(displayname: :asc).ransack(search_params[:q])
    users = @q.result
    @pagy, @users = pagy_countless(users, items: 50)
  end

  def show
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_accesses
    @accesses = Access.where(user_id: params[:id]).joins(:role).order(approved: :asc, created_at: :desc)
  end

end