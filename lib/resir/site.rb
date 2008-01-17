#
# Resir::Site represents a single website.
#
# Resir::Site instances are meant to be run by Resir::Server, 
# but they can hold their own.
#
# A Resir::Site can handle a Rack #call, just as Resir::Server can.
#
# The actual responses to #calls are handled by a Resir::Site::Responder
# that is created (and then discarded) for each #call to a site
#
class Resir::Site
  include IndifferentVariableHash

  attr_accessor :server, :responder

  def call env
    reply          = responder.new self
    reply.request  = Rack::Request.new env
    reply.response = Rack::Response.new
    reply.call env
  end

  def site; self; end
  def load_helpers *args, &block
    unless args.empty?
      puts "i would require these helpers ... #{args.inspect}"
    end
    
    unless block.nil?
      responder.class_eval &block
    end
  end
  def load_filters *args, &block
    unless args.empty?
      puts "i would require these filters ... #{args.inspect}"
    end
    
    unless block.nil?
      puts "NEED TO REQUIRE FILTERS"
    end
  end

  # root_dir:: absolute or relative path to site's root directory  
  def initialize root_dir
    require 'resir/responder'
    @responder = Resir::Site::Responder.clone

    init_variables
    init_filters

    self.root_directory = root_dir
    self.name           = File.basename self.root_directory

    siterc = File.join self.root_directory, Resir.site_rc_file
    eval File.read(siterc) unless not File.file?siterc
  end

  def init_filters
    # initially, filters was one of the sites' normal variables that
    # falls back to Resir, but filters need to live on their own.
    filter_hash = {}
    filter_hash.instance_eval {
      def []( key )
        unless keys.include?key
          Resir.filters[key] # we don't have it - ask Resir for it
        else
          super # self[key] # we seem to have this value - go ahead and return it
        end
      end
      def method_missing name, *args
        if name.to_s[/=$/] # trying to SET value
          name = name.to_s.sub( /=$/, '' )

          self[name] = args.first # nomatter what, if we're SETTING, we set it locally

        else # trying to GET value
          name = name.to_s

          unless keys.include?name
            Resir.filters[name] # we don't have it - ask Resir for it
          else
            self[name] # we seem to have this value - go ahead and return it
          end

        end
      end
    }
    self.filters = filter_hash
  end

  def init_variables
    # makes variables an empty hash and sets them up with method_missing
    # to fall back to Resir if it has something that the site doesn't
    @variables = {}
    self.variables.instance_eval {
      def method_missing_with_fallback name, *args
        return method_missing_without_fallback(name, *args) if name.to_s[/=$/]

        super_result = method_missing_without_fallback name, *args
        return super_result if super_result and not super_result.nil?

        name = name.to_s.sub( /=$/, '')
        (Resir.variables.keys.include?name) ? Resir.variables[name] : nil
      end
      alias method_missing_without_fallback method_missing
      alias method_missing method_missing_with_fallback
    }
  end

  def get_template name
    return nil if name.nil? or name.empty?
    looking_for = File.join template_rootpath, name 
    return template_basename(looking_for) if File.file?looking_for
    template_basename Dir["#{looking_for}.*"].sort.select{ |match| File.file?match }.first
  end

  def template_rootpath
    File.join( self.root_directory, self.template_directory ).sub /\/$/,''
  end
  
  def template_basename name
    return name if name.nil? or name.empty?
    name.sub "#{template_rootpath}/", ''
  end
  
  def template_realpath name
    "#{template_rootpath}/#{name}"
  end

  def safe_name       # safe for use in url
    self.name.gsub /[^a-zA-Z0-9_.-]/, ''
  end
  
  def safe_host_name  # safe for use as a host name (safe_name with _ => -)
    self.safe_name.gsub '_', '-'
  end

end
