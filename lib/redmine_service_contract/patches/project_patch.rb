module RedmineServicesContract
  module Patches
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_many :service_contracts
        end
      end
      
      module InstanceMethods
        def open_service_contracts
            service_contracts.select { |service_contract| !service_contract.closed }
        end
        def open_service_contracts_for_all_ancestor_projects(contracts=self.open_service_contracts)
          if self.parent != nil
            parent = self.parent
            contracts +=  parent.open_service_contracts_for_all_ancestor_projects
          end
          return contracts
      end
      end
    end
  end
end
      
unless Project.included_modules.include?(RedmineServicesContract::Patches::ProjectPatch)
  Project.send(:include, RedmineServicesContract::Patches::ProjectPatch)
end