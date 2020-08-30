
require 'redmine'
require 'scenic/mysql_adapter'

Scenic.configure do |config|
  config.database = Scenic::Adapters::MySQL.new
end

begin
  require 'config/initializers/session_store.rb'
  rescue LoadError
end

def init
  Dir::foreach(File.join(File.dirname(__FILE__), 'lib','redmine_service_contract')) do |file|
    next unless /\.rb$/ =~ file
    require_dependency File.join('redmine_service_contract',file)
  end
  Dir::foreach(File.join(File.dirname(__FILE__), 'lib','redmine_service_contract','patches')) do |file|
    next unless /\.rb$/ =~ file
    require_dependency File.join('redmine_service_contract','patches',file)
  end
end

if Rails::VERSION::MAJOR >= 5
  ActiveSupport::Reloader.to_prepare do
    init
  end
elsif Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    init
  end
else
  Dispatcher.to_prepare :redmine_service_contract do
    init
  end
end

Redmine::Plugin.register :redmine_service_contract do
  name 'Redmine Service Contract'
  author 'LS MARK'
  description 'This is a plugin for maintain service contract'
  version '1.0.0'
  url 'https://daxonet.com'
  author_url 'https://daxonet.com/about'
end

#require 'service_contract/internals'
#require 'redmine_service_contract/hooks'
#require 'service_contract/service_contract_hooks'

Redmine::AccessControl.map do |map|
  map.project_module :service_contracts do |pmap|
    pmap.permission :view_service_contracts, { service_contracts: [:index, :show, :autocomplete, :context_menu] }, read: true
    pmap.permission :manage_service_contracts, { service_contracts: [:new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update] }
  end 
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :service_contracts, { controller: 'service_contracts', action: 'index', project_id: nil }, caption: :label_service_contracts
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :service_contracts, { controller: 'service_contracts', action: 'index' }, param: :project_id, caption: :label_service_contracts
end

CustomFieldsHelper::CUSTOM_FIELDS_TABS << {name: 'ServiceContractCustomField', partial: 'custom_fields/index', label: :label_service_contracts}

Redmine::Search.map do |search|
  search.register :service_contracts
end