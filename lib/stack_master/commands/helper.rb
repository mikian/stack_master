require 'active_support/concern'

module StackMaster
  module Commands
    module Helper
      extend ActiveSupport::Concern

      included do
        def window_size
          size = ENV["COLUMNS"] || `tput cols`.chomp

          if size.nil? || size == ""
            80
          else
            size.to_i
          end
        end
      end
    end
  end
end
