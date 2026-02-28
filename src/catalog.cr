require "./definition"

class Pug
  class Catalog
    def initialize
      @definitions = [] of Definition
    end

    def load(path : String)
      File.open(path) do |file|
        @definitions += Array(Definition).from_json(file)
      end
    end

    def find(name : String) : Definition
      @definitions.reverse_each do |definition|
        return definition if definition.name == name
      end
      abort "fatal: unknown '#{name}' dependency"
    end
  end
end
