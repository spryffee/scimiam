require 'csv'

class RolesController < ApplicationController
  before_action :authorize
  before_action :is_admin?
  before_action :set_role, only: %i[show edit update destroy]
  before_action :set_accesses, only: %i[show]
  before_action :load_approval_workflows, only: [:new, :edit, :create, :update]

  def index
    search_params = params.permit(:format, :page, q: [:name_cont, :s])
    @q = Role.select(:id, :name, :is_active).order(name: :asc).ransack(search_params[:q])
    roles = @q.result
    @pagy, @roles = pagy_countless(roles, items: 50)
  end
  
  def show
    # in role details we search over accesses
    search_params = params.permit(:id, :format, :page, q: [:user_displayname_cont, :s])
    @q = Access.where(role_id: params[:id]).ransack(search_params[:q])
    accesses = @q.result
    @pagy, @accesses = pagy_countless(accesses, items: 50)
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      process_user_csv if params[:role][:user_csv].present?
      flash[:success] = "Created"
      render turbo_stream: turbo_stream.action(:redirect, role_path(@role))
    else
      flash.now[:errors] = @role.errors.full_messages
      render :new
    end
  end

  def edit
  end

  def update
    if @role.update(role_params)
      process_user_csv if params[:role][:user_csv].present?
      flash[:success] = "Updated"
      render turbo_stream: turbo_stream.action(:redirect, role_path(@role))
    else
      flash.now[:errors] = @role.errors.full_messages
      render :edit
    end
  end

  def destroy
    if @role.destroy
      flash[:success] = "Deleted"
      redirect_to roles_path
    else
      flash[:errors] = @role.errors.full_messages
      redirect_to role_path
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def set_accesses
    @accesses = Access.where(role_id: params[:id])
  end

  def role_params
    params.require(:role).permit(
      :name, 
      :approval_workflow_id, 
      :term,
      :workspace_connection_id,
      :workspace_group
    )
  end

  def load_approval_workflows
    @approval_workflows = ApprovalWorkflow.all
  end

  def process_user_csv
    csv_file = params[:role][:user_csv]
    CSV.foreach(csv_file.path, headers: true) do |row|
      user_email = row['email'] # Assuming the CSV has a header 'email'
      user = User.find_by(work_email_address: user_email)
      if user
        access = Access.new(user: user, role: @role, approved: true, status: :approved)
        # access.approve!(current_user.id) # Cannot use this since we are bypassing standard approval workflow
        if access.save! 
          AuditLog.create(event: "Access role #{@role.name} approved for #{user.displayname} by automation")
        end
      else
        Rails.logger.warn "User with email #{user_email} not found. Access not created."
      end
    end
  end
end
