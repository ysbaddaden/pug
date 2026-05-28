require "./config"
require "./catalog"
require "./package"

class Pug
  def self.new(pug_path : String)
    packages = File.open(pug_path, "r") do |file|
      Array(Package).from_json(file)
    end
    new(packages)
  end

  getter catalog : Catalog
  getter packages : Array(Package)

  def initialize(@packages : Array(Package))
    @catalog = Catalog.new
    @system = System.new
  end

  def load_catalog(path)
    @catalog.load(path)
  end

  def env_path
    paths = [] of String

    @packages.each do |pkg|
      installdir = File.join(@system.bindir, "#{pkg.name}-#{pkg.version}")
      next unless Dir.exists?(installdir)

      executable_name = {% if flag?(:win32) %} "#{pkg.name}.exe" {% else %} pkg.name {% end %}

      Dir.glob(File.join(installdir, "**", executable_name)).each do |executable_path|
        if File.exists?(executable_path) && ({% flag?(:win32) %} || File::Info.executable?(executable_path))
          paths << File.dirname(executable_path)
          break
        end
      end
    end

    if path = ENV["PATH"]?
      paths << path
    end

    paths.join(@system.env_path_separator)
  end

  def install_command
    @packages.each do |pkg|
      installdir = File.join(@system.bindir, "#{pkg.name}-#{pkg.version}")
      next if Dir.exists?(installdir)

      definition = @catalog.find(pkg.name)
      url = definition.url("x86_64", "linux", pkg.version)

      Dir.mkdir_p(installdir)

      # basically: curl -sL $url | tar zx -C $installdir (without an extra shell)
      if @system.compressed?(url)
        STDERR.puts @system.shell_download_and_decompress(url, installdir)
        download = Process.new(*@system.download(url), input: :close, output: :pipe, error: :inherit)
        decompress = Process.new(*@system.decompress(url, installdir), input: download.output, output: :inherit, error: :inherit)
        exit(1) unless download.wait.success? && decompress.wait.success?
      else
        filename = Path[installdir, pkg.name].to_s
        STDERR.puts @system.shell_download(url, filename)
        download = Process.new(*@system.download(url, filename), input: :close, output: :close, error: :inherit)
        exit(1) unless download.wait.success?
        {% if flag?(:unix) %} File.chmod(filename, 0o775) {% end %}
      end
    end
  end

  def run_command(argv)
    Process.exec(*@system.shell_run(Process.quote(argv)),
                 input: :inherit,
                 output: :inherit,
                 error: :inherit,
                 env: { "PATH" => env_path })
  end

  def shell_command
    Process.exec(*@system.shell_interactive,
                 input: :inherit,
                 output: :inherit,
                 error: :inherit,
                 env: { "PATH" => env_path })
  end
end
