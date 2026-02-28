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
  end

  def load_catalog(path)
    @catalog.load(path)
  end

  def env_path
    paths = [] of String

    @packages.each do |pkg|
      installdir = File.join(BINDIR, "#{pkg.name}-#{pkg.version}")
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

    paths.join({% if flag?(:win32) %} ';' {% else %} ':' {% end %})
  end

  ## COMMANDS

  def install_command
    @packages.each do |pkg|
      installdir = File.join(BINDIR, "#{pkg.name}-#{pkg.version}")
      next if Dir.exists?(installdir)

      definition = @catalog.find(pkg.name)
      url = definition.url("x86_64", "linux", pkg.version)

      command =
        case url
        when .ends_with?(".zip")
          %(curl -sL #{url.inspect} | 7z x -si -o#{installdir.inspect})
        when .ends_with?(".tar.gz")
          %(curl -sL #{url.inspect} | tar zx -C #{installdir.inspect})
        else
          abort "fatal: unknown file extension #{File.basename(url)}"
        end

      mkdir installdir
      invoke command, verbose: true
    end
  end

  def run_command(argv)
    Process.exec(SHELL, {"-c", Process.quote(argv)},
                 input: Process::Redirect::Inherit,
                 output: Process::Redirect::Inherit,
                 error: Process::Redirect::Inherit,
                 env: { "PATH" => env_path })
  end

  def shell_command
    Process.exec(SHELL, INTERACTIVE_SHELL_ARGV,
                 input: Process::Redirect::Inherit,
                 output: Process::Redirect::Inherit,
                 error: Process::Redirect::Inherit,
                 env: { "PATH" => env_path })
  end

  private def invoke(command, verbose = false)
    STDERR.puts command if verbose

    status = Process.run(SHELL, {"-c", command},
                         input: Process::Redirect::Close,
                         output: Process::Redirect::Inherit,
                         error: Process::Redirect::Inherit)
    exit(1) unless status.success?
  end

  private def mkdir(path, verbose = false)
    {% if flag?(:win32) %}
      invoke %(New-Item -ItemType Directory -Path #{Process.quote(path)} -Force), verbose
    {% else %}
      invoke %(mkdir -p #{Process.quote(path)}), verbose
    {% end %}
  end
end
