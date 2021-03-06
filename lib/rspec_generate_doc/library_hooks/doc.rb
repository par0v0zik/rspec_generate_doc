require 'rspec/rails'
require 'rspec_generate_doc/generate_file'
require 'rspec_generate_doc/decorators/action'

module RspecGenerateDoc
  module LibraryHooks
    module Doc
      CORRECT_TYPE = :controller

      ::RSpec.configure do |config|
        config.before(:context) do
          @actions = []
          @is_incorrect_type = self.class.metadata[:type] != CORRECT_TYPE
        end

        config.after(:each) do
          next if @is_incorrect_type || try(:skip_this) || @skip_this
          name = self.class.description
          parent = self.class.parent
          loop do
            break if parent.nil? || parent.description == self.class.top_level_description
            name = "#{parent.description} #{name}"
            parent = parent.parent
          end

          api_params = try(:api_params) || @api_params || {}
          opntions = try(:api_opntions) || @api_opntions || {}
          new_action = RspecGenerateDoc.configuration.action_decorator
                                      .new(name: name, response: response, api_params: api_params, options: opntions)
          @actions << new_action unless @actions.index { |action| action.name == new_action.name }
        end

        config.after(:context) do
          next if @is_incorrect_type
          parent = try(:parent_name) || @parent_name || self.class.top_level_description
          RspecGenerateDoc::GenarateFIle.new(parent: parent, actions: @actions).create_file_by_template
        end
      end
    end
  end
end
