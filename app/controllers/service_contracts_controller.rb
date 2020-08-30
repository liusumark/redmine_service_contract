class ServiceContractsController < ApplicationController

  menu_item :service_contracts

  before_action :authorize_global
  before_action :find_service_contract, only: [:show, :edit, :update, :timelog]
  before_action :find_service_contracts, only: [:context_menu, :bulk_edit, :bulk_update, :destroy]
  before_action :find_project

  helper :trackers
  helper :service_contracts
  helper :custom_fields, :context_menus, :attachments, :issues
  include_query_helpers

  accept_api_auth :index, :show, :create, :update, :destroy

  def index

    retrieve_query(ServiceContractQuery)
    @entity_count = @query.service_contracts.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.service_contracts(offset: @entity_pages.offset, limit: @entity_pages.per_page)

  end

  def show
    retrieve_query(ServiceContractsIssueQuery)
    @query.service_contract = @service_contract

    respond_to do |format|
      format.html { 
        @entity_count = @query.issues.count
        @entity_pages = Paginator.new @entity_count, per_page_option, params['page']    
        @entities = @query.issues(offset: @entity_pages.offset, limit: @entity_pages.per_page)
        render :layout => !request.xhr? 
      }
      format.api
      format.js
      format.pdf {
        @entities = @query.issues(:limit => Setting.issues_export_limit.to_i)
        send_file_headers! :type => 'application/pdf', :filename => 'service_contracts.pdf'
      }
      format.csv {
        @issues = @query.issues(:limit => Setting.issues_export_limit.to_i)
        send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'service_contract_issues.csv')
      }
    end
  end

  def timelog
    retrieve_query(ServiceContractTimelogQuery)
    @query.service_contract = @service_contract

    
    #raise @query.inspect
    respond_to do |format|
      format.html {
        @entity_count = @query.service_contract_timelogs.count
        @entity_pages = Paginator.new @entity_count, per_page_option, params['page']    
        @entities = @query.service_contract_timelogs(offset: @entity_pages.offset, limit: @entity_pages.per_page)
        render :layout => !request.xhr?      
      }
      format.api
      format.js
      format.csv {
        @issues = @query.service_contract_timelogs(:limit => Setting.issues_export_limit.to_i)
        send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'service_contract_timelogs.csv')
      }
    end
  end

  def new
    @service_contract = ServiceContract.new
    @service_contract.project = @project
    @service_contract.safe_attributes = params[:service_contract]
    @trackers = Tracker.sorted.to_a

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @service_contract = ServiceContract.new author: User.current
    @service_contract.project = @project
    @service_contract.safe_attributes = params[:service_contract]
    @service_contract.save_attachments(params[:attachments] || (params[:service_contract] && params[:service_contract][:uploads]))
    @trackers = Tracker.sorted.to_a

    respond_to do |format|
      if @service_contract.save
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default service_contract_path(@service_contract)
        end
        format.api { render action: 'show', status: :created, location: service_contract_url(@service_contract) }
        format.js { render template: 'common/close_modal' }
      else
        format.html { render action: 'new' }
        format.api { render_validation_errors(@service_contract) }
        format.js { render action: 'new' }
      end
    end
  end

  def edit
    @service_contract.safe_attributes = params[:service_contract]
    @trackers = Tracker.sorted.to_a
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @service_contract.safe_attributes = params[:service_contract]
    @service_contract.save_attachments(params[:attachments] || (params[:service_contract] && params[:service_contract][:uploads]))

    respond_to do |format|
      if @service_contract.save
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default service_contract_path(@service_contract)
        end
        format.api { render_api_ok }
        format.js { render template: 'common/close_modal' }
      else
        format.html { render action: 'edit' }
        format.api { render_validation_errors(@service_contract) }
        format.js { render action: 'edit' }
      end
    end
  end

  def destroy
    @service_contracts.each(&:destroy)

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default service_contracts_path
      end
      format.api { render_api_ok }
    end
  end

  def bulk_edit
  end

  def bulk_update
    unsaved, saved = [], []
    attributes = parse_params_for_bulk_update(params[:service_contract])
    @service_contracts.each do |entity|
      entity.init_journal(User.current) if entity.respond_to? :init_journal
      entity.safe_attributes = attributes
      if entity.save
        saved << entity
      else
        unsaved << entity
      end
    end
    respond_to do |format|
      format.html do
        if unsaved.blank?
          flash[:notice] = l(:notice_successful_update)
        else
          flash[:error] = unsaved.map{|i| i.errors.full_messages}.flatten.uniq.join(",\n")
        end
        redirect_back_or_default :index
      end
    end
  end

  def context_menu
    if @service_contracts.size == 1
      @service_contract = @service_contracts.first
    end

    can_edit = @service_contracts.detect{|c| !c.editable?}.nil?
    can_delete = @service_contracts.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url

    @service_contract_ids, @safe_attributes, @selected = [], [], {}
    @service_contracts.each do |e|
      @service_contract_ids << e.id
      @safe_attributes.concat e.safe_attribute_names
      attributes = e.safe_attribute_names - (%w(custom_field_values custom_fields))
      attributes.each do |c|
        column_name = c.to_sym
        if @selected.key? column_name
          @selected[column_name] = nil if @selected[column_name] != e.send(column_name)
        else
          @selected[column_name] = e.send(column_name)
        end
      end
    end

    @safe_attributes.uniq!

    render layout: false
  end

  def autocomplete
  end

  private

  def find_service_contract
    @service_contract = ServiceContract.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_service_contracts
    @service_contracts = ServiceContract.visible.where(id: (params[:id] || params[:ids])).to_a
    @service_contract = @service_contracts.first if @service_contracts.count == 1
    raise ActiveRecord::RecordNotFound if @service_contracts.empty?
    raise Unauthorized unless @service_contracts.all?(&:visible?)

    @projects = @service_contracts.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project ||= @service_contract.project if @service_contract
    @project ||= Project.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
