class Pug
  FILENAME = "pug.json"

  class System
    enum Variant
      Powershell
      Shell
    end

    property variant : Variant

    def self.new
      {% if flag?(:win32) %}
        new(:powershell)
      {% else %}
        new(:shell)
      {% end %}
    end

    def initialize(@variant : Variant)
    end

    def bindir
      case @variant
      in Variant::Powershell
        File.expand_path("~/AppData/Local/pug/cache", home: true)
      in Variant::Shell
        File.expand_path("~/.cache/pug", home: true)
      end
    end

    def env_path_separator
      case @variant
      in Variant::Powershell
        ';'
      in Variant::Shell
        ':'
      end
    end

    def shell_run(command)
      case @variant
      in Variant::Powershell
        {"powershell", ["-c", command]}
      in Variant::Shell
        {"sh", ["-c", command]}
      end
    end

    def shell_interactive
      case @variant
      in Variant::Powershell
        {"powershell", [] of String}
      in Variant::Shell
        {"sh", ["-i"]}
      end
    end

    def compressed?(url)
      url.ends_with?(".tar.gz") ||
        url.ends_with?(".zip")
    end

    def shell_download(url, filename)
      %(curl -sL #{Process.quote(url)} -o #{Process.quote(filename)})
    end

    def shell_download_and_decompress(url, dir)
      case url
      when .ends_with?(".zip")
        %(curl -sL #{Process.quote(url)} | 7z x -si -o#{Process.quote(dir)})
      when .ends_with?(".tar.gz")
        %(curl -sL #{Process.quote(url)} | tar zx -C #{Process.quote(dir)})
      else
        abort "fatal: unknown file extension #{File.basename(url)}"
      end
    end

    def download(url, filename = nil)
      if filename
        {"curl", ["-sL", url, "-o", filename]}
      else
        {"curl", ["-sL", url]}
      end
    end

    def decompress(url, dir)
      case url
      when .ends_with?(".zip")
        {"7z", ["x", "-si", "-o#{dir}"]}
      when .ends_with?(".tar.gz")
        {"tar", ["zx", "-C", dir]}
      else
        abort "fatal: unknown file extension #{File.basename(url)}"
      end
    end

    def mkdir_p(path)
      case @variant
      in Variant::Powershell
        %(New-Item -ItemType Directory -Path #{Process.quote(path)} -Force)
      in Variant::Shell
        %(mkdir -p #{Process.quote(path)})
      end
    end
  end
end
