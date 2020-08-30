class ServiceContractsIssue < ActiveRecord::Base
    include Redmine::SafeAttributes

    belongs_to :issue
    belongs_to :service_contract, :class_name => "ServiceContract"

    safe_attributes('service_contract_id','use_spent_hours','hours')
    
    validate :validate_service_contracts_issue
    
    def used_hours
        if use_spent_hours
            l_hours_short(self.issue.total_spent_hours).html_safe
        else
            l_hours_short(hours).html_safe
        end
    end

    def validate_service_contracts_issue
      if service_contract && !service_contract.validate_hours_error(self)
        errors.add :service_contracts_hours, 'has exceeded maximum level.'
      end
    end
end
