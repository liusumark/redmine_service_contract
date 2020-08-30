class CreateServiceContractTimelogs < ActiveRecord::Migration[5.2]
  def change
    create_view('service_contract_timelogs', sql_definition:File.read(File.expand_path('../../views/service_contract_timelogs_v01.sql', __FILE__)))
  end
end
