require "json"

class Pug
  class Definition
    include JSON::Serializable

    getter name : String
    getter urls : Hash(String, String)

    # URL template variables:
    # - `$VERSION` — 1.2.3 or 4.5.6-alpha
    # - `$ARCH` — for example aarch64 or x86_64
    # - `$GOARCH` — for example arm64 or amd64
    def url(arch, system, version)
      template = @urls[system]?
      abort "fatal: no URL template for #{@name} on #{system}" unless template

      template
        .gsub("$VERSION", version)
        .gsub("$ARCH", arch)
        .gsub("$GOARCH", goarch(arch))
    end

    def native_url(version)
      url(System.arch, System.name, version)
    end

    private def goarch(arch)
      case arch
      when "aarch64"
        "arm64"
      when "x86_64"
        "amd64"
      end
    end
  end
end
