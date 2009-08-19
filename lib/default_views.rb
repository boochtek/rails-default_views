module ActionController
  class Base
    def self.default_views()
      include BoochTek::Rails::DefaultViews
    end
  end
end


module BoochTek
  module Rails
    module DefaultViews

      # NOT USED YET -- FALLBACK_VIEW_DIR = Dir.join(RAILS_ROOT, 'app', 'views', 'default')

      def self.included(base)
        base.send(:include, InstanceMethods) # Have to use send(:include) because include is a private method.
      end

      module InstanceMethods
        protected

        # Look for view templates in app/views/default if they aren't in app/views/#{controller_name}.
        # TODO/FIXME: Needs some refactoring.
        # There are only a few cases where a template is used:
        #   render (which renders default_template)
        #   render :action => :some_action (or just render :some_action or render 'some_action')
        #   render :file => '/path/to/some/file'  (or just render '/path/to/some/file') -- No need to handle this one, since they explicitly specified the full path.
        #   render :template => 'some/file'  (or just render 'some/file')
        # NOTE: For Rails 3, Yehuda Katz suggests overriding _determine_template to provide the fallback -- path http://yehudakatz.com/2009/07/19/rails-3-the-great-decoupling/.
        def render(options = nil, extra_options = {}, &block) #:doc:
          super(options, extra_options, &block)
        rescue ActionView::MissingTemplate => e # e.path contains full path to template file
          erase_render_results # Make sure we don't end up with a DoubleRenderError for trying to render a second time. FIXME: Not sure this is necessary.

          if options.nil?
            options = default_template_name.gsub(/^#{controller_name}\//, 'default/')
            extra_options[:layout] = true

          elsif options.is_a?(String) || options.is_a?(Symbol) && options.to_s.index('/').nil? # we were passed an action (no slash)
            options = default_template_name(options.to_s).to_s.gsub(/^#{controller_name}\//, 'default/')

          elsif options.has_key?(:action)
            options[:template] = default_template_name(options[:action]).to_s.gsub(/^#{controller_name}\//, 'default/')
            options.delete(:action)

          else # I don't think this should happen, but this might be another way to handle this more simply.
            options = e.path.gsub(/^#{controller_name}\//, 'default/')
          end

          # BUG/FIXME: If it doesn't find it this time, the error message should really tell them what it was ORIGINALLY looking for.
          super(options, extra_options) # No need for &block; it's only valid for render :update, which doesn't use ActionView::Template, so can't generate MissingTemplate.
        end

      end

    end
  end
end
