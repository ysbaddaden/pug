require "./pug"

pug = Pug.new(Pug::FILENAME)
pug.load_catalog(Pug.catalog_path)

case ARGV[0]?
when "install"
  pug.install_command
when "outdated"
  pug.outdated_command
#when "upgrade"
#  TODO: find upgradeable pkgs
#  TODO: update pug.json (unless up to date)
#  TODO: install new pkgs (unless up to date)
when "run"
  # TODO: error unless ARGV.size > 1
  pug.install_command
  pug.run_command(ARGV[1..])
when "shell"
  pug.install_command
  pug.shell_command
#when "export"
#  TODO: export (power)shell script to install dependencies & run a command
#  pug.export_command(ARGV[1]? || "sh")
when "env"
  {% if flag?(:win32) %}
    print "$env:PATH="
    puts pug.env_path.inspect
  {% else %}
    print "export PATH="
    puts pug.env_path
  {% end %}
when "version"
  puts "pug 0.1.0"
else
  puts "usage: pug [command] [args]"
  puts
  puts "commands:"
  puts "   install   install packages defined in #{Pug::FILENAME}"
  puts "   outdated  lists upgradable packages defined in #{Pug::FILENAME}"
  puts "   run       run a shell command with packages in PATH"
  puts "   shell     starts an interactive shell with packages in PATH"
  puts "   env       show PATH"
  puts "   version   show version"
  puts "   help      show this message"
end
