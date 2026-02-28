class Pug
  FILENAME = "pug.json"

  {% if flag?(:win32) %}
    BINDIR = File.expand_path("~/AppData/Local/pug/cache", home: true)
    SHELL = "powershell"
    INTERACTIVE_SHELL_ARGV = [] of String
  {% else %}
    BINDIR = File.expand_path("~/.cache/pug", home: true)
    SHELL = "sh"
    INTERACTIVE_SHELL_ARGV = ["-i"]
  {% end %}
end
