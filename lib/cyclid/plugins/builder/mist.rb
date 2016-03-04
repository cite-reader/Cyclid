require 'mist/pool'
require 'mist/client'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Mist build host
      class MistHost < BuildHost
        # SSH is the only acceptable Transport
        def transports
          ['ssh']
        end
      end

      # Mist builder. Calls out to Mist to obtain a build host instance.
      class Mist < Builder
        def initialize
          pool = ::Mist::Pool.get
          @client = ::Mist::Client.new(pool)
        end

        # Create & return a build host
        def get(args = {})
          args.symbolize_keys!

          Cyclid.logger.debug "mist: args=#{args}"

          # If there is one, split the 'os' into a 'distro' and 'release'
          if args.key? :os
            match = args[:os].match(/\A(\w*)_(.*)\Z/)
            distro = match[1] if match
            release = match[2] if match
          else
            # No OS was specified; use the default
            # XXX Defaults should be configurable
            distro = 'ubuntu'
            release = 'trusty'
          end

          begin
            result = @client.call(:create, distro: distro, release: release)
            Cyclid.logger.debug "mist result=#{result}"

            raise "failed to create build host: #{result['message']}" \
              unless result['status']

            buildhost = MistHost.new(name: result['name'],
                                     host: result['ip'],
                                     username: result['username'],
                                     password: nil,
                                     server: result['server'],
                                     distro: distro,
                                     release: release)
          rescue MessagePack::RPC::TimeoutError => ex
            Cyclid.logger.error "Mist create call timedout: #{ex}"
            raise "mist failed: #{ex}"
          rescue StandardError => ex
            Cyclid.logger.error "couldn't get a build host from Mist: #{ex}"
            raise "mist failed: #{ex}"
          end

          Cyclid.logger.debug "mist buildhost=#{buildhost.inspect}"
          return buildhost
        end

        # Destroy the build host
        def release(_transport, buildhost)
          name = buildhost[:name]
          server = buildhost[:server]

          begin
            @client.call(:destroy, name: name, server: server)
          rescue MessagePack::RPC::TimeoutError => ex
            Cyclid.logger.error "Mist destroy timed out: #{ex}"
          end
        end

        # Register this plugin
        register_plugin 'mist'
      end
    end
  end
end
