require "./config"
require "./catalog"
require "./package"
require "./concurrently"
require "http"
require "openssl"
require "semantic_version"

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

  def load_catalog(path : Path)
    if File.exists?(path)
      @catalog.load(path)
    else
      abort "fatal: expected catalog at #{path}"
    end
  end

  def env_path
    paths = [] of String

    @packages.each do |pkg|
      installdir = @system.bindir("#{pkg.name}-#{pkg.version}")
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

  # TODO: drop dependency on *curl*, *tar* and *zip* external executables
  def install_command
    Concurrently.each(@packages) do |pkg|
      installdir = @system.bindir("#{pkg.name}-#{pkg.version}")
      next if Dir.exists?(installdir)

      definition = @catalog.find(pkg.name)
      url = definition.native_url(pkg.version)

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

  def outdated_command
    Concurrently.each(@packages) do |pkg|
      next unless latest = @catalog.find(pkg.name).latest?
      next unless pattern = latest.redirect?

      response = HTTP::Client.head(latest.url)
      next unless response.status.redirection?
      next unless response.headers["location"]? =~ Regex.new(Regex.escape(pattern).gsub("\\$VERSION", "(.*)"))
      version = $1

      if SemanticVersion.parse(version) > SemanticVersion.parse(pkg.version)
        print "- #{pkg.name} #{version} (installed #{pkg.version})\n"
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
