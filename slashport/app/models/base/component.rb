
module SlashPort
  class Component
    @@subclasses = Array.new
    @@components = Array.new

    def variables
      return self.class.variables
    end

    def configs
      return self.class.configs
    end

    def get_variables(filter=nil)
      get_things(variables, filter)
    end

    def get_configs(filter=nil)
      get_things(configs, filter)
    end

    def _want(value, pattern)
      if pattern.is_a?(Regexp)
        return !!(!pattern or value =~ pattern)
      else
        return !!(!pattern or value == pattern)
      end
    end

    def get_things(thing, filter=nil)
      return unless _want(self.class.label, filter["component"])

      data = []

      thing.each do |section, var|
        next unless _want(section, filter["section"])
        results = self.send(var.handler)
        if var.is_a?(MultiVariable)
          results.each do |key,value|
            next unless _want(key, filter[key])
            data << {
              "component" => self.class.label,
              "section" => section,
              "key" => key,
              "value" => value,
            }
          end
        else 
          results = [results] if !results.is_a?(Array)

          results.each do |result|
            if result.is_a?(Hash)
              result.merge!({
                "component" => self.class.label,
                "section" => section,
              })
            else
              result = {
                "component" => self.class.label,
                "section" => section,
                "value" => result,
              }
            end

            keep = true
            filter.each do |filterkey,filtervalue|
              want = _want(result[filterkey], filtervalue)
              if !want
                keep = false
                break
              end
            end

            data << result if keep
          end
        end
      end
      return data
    end

    def path(*names)
      return [self.class.label, *names].join("/")
    end

    # See Class#inherited for what this method 
    def self.inherited(subclass)
      puts "#{subclass.name} inherits #{self.name}"
      @@subclasses << subclass

      if subclass.respond_to?(:class_initialize)
        subclass.class_initialize
      end
    end # def self.inherited

    # class-level to easily map a variable name to a method
    # arguments:
    #   :name => variable name
    #   :handler => method handler name
    #   :doc => variable documentation
    #   :sort => [optional] array of keys for sort (used with var.text output)
    def self.variable(options = {})
      if options[:doc] == nil
        raise "Variable #{self.name}/#{name} has no description"
      end
      name = options[:name]
      puts "#{self.name}: new variable #{name}"
      options[:sort] ||= []

      # remember: this is a class-level instance variable
      @variables[options[:name]] = Variable.new(options[:handler], options[:doc], options[:sort])
    end # def self.variable

    def self.multivariable(name, handler, description=nil)
      if description == nil
        raise "Variable #{self.name}/#{name} has no description"
      end
      puts "#{self.name}: new multivariable #{name}"

      # remember: this is a class-level instance variable
      @variables[name] = MultiVariable.new(handler, description)
    end # def self.multivariable

    # class-level to easily map a variable name to a handler
    def self.config(name, handler, description=nil)
      if description == nil
        raise "Config #{self.name}/#{name} has no description"
      end
      puts "#{self.name}: new config #{name}"

      # remember: this is a class-level instance variable
      @configs[name] = Variable.new(handler, description)
    end # def self.config

    def self.multiconfig(name, handler, description=nil)
      if description == nil
        raise "Config #{self.name}/#{name} has no description"
      end
      puts "#{self.name}: new multiconfig #{name}"

      # remember: this is a class-level instance variable
      @configs[name] = MultiVariable.new(handler, description)
    end # def self.multiconfig

    def self.configs(filter=nil)
      return @configs
    end

    def self.variables(filter=nil)
      return @variables
    end

    # class-level initialization. This is called when ruby first
    # creates this class object, a hack made possible by
    # overriding Class#inherited (see 'def inherited' above).
    def self.class_initialize
      puts "#{self}::class_initialize"
      # remember, this is a class-level instance variable
      @variables = Registry.new
      @configs = Registry.new
      @label = self.name.split("::")[-1].downcase
    end # def.class_initialize

    # Show me all subclasses of SlashPort::Component
    def self.components
      if @@components.length == 0
        @@subclasses.each do |klass|
          @@components << klass.new
        end
      end
      return @@components
    end # def self.components

    def self.get_things(thing, filter=nil)
      data = []
      self.components.each do |component|
        result = component.send("get_#{thing}", filter)
        if result
          data += result
        end
      end
      return data
    end

    def self.get_variables(filter=nil)
      return self.get_things("variables", filter)
    end

    def self.get_configs(filter=nil)
      return self.get_things("configs", filter)
    end

    def self.label
      return @label
    end
  end # class Component
end # module SlashPort
