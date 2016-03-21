# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for Provisioner plugins
      class Provisioner < Base
        # Return the 'human' name for the plugin type
        def self.human_name
          'provisioner'
        end

        # Process the environment, performing all of the steps necasary to
        # configure the host according to the given environment; this can
        # include adding repositories, installing packages etc.
        def prepare(_transport, _buildhost, _env = {})
          false
        end
      end
    end
  end
end

require_rel 'provisioner/*.rb'