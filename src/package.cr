require "json"

class Pug
  class Package
    include JSON::Serializable
    getter name : String
    getter version : String
  end
end
