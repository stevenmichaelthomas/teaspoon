require "json"

class Teabag::Formatter

  RED = 31
  GREEN = 32
  YELLOW = 33
  CYAN = 36

  def initialize(suite_name = "default")
    log "Teabag starting for: #{suite_name}...\n\n"
  end

  def process(line)
    return if output_from(line)
    log line
  end

  def spec(spec)
    case spec['status']
      when "pass" then log ".", GREEN
      when "skipped" then log "*", YELLOW
      else log "F", RED
    end
  end

  def error(error)
    log "#{error['msg']}\n", RED
    for trace in error['trace'] || []
      log "  # #{filename(trace['file'])}:#{trace['line']}#{trace['function'].present? ? " -- #{trace['function']}" : ""}\n", CYAN
    end
    log "\n"
  end

  def results(results)
    total = results['total']
    fails = results['failures'].length
    log "\n\n"
    failures(results['failures']) if fails > 0
    log "Finished in #{results['elapsed']} seconds\n"
    log "#{pluralize("example", total)}, #{pluralize("failure", fails)}\n\n", fails > 0 ? RED : GREEN
    raise Teabag::FailureException if fails > 0
  end

  private

  def pluralize(str, value)
    value == 1 ? "#{value} #{str}" : "#{value} #{str}s"
  end

  def failures(failures)
    log "Failures:\n"
    failures.each_with_index do |failure, index|
      log "\n  #{index + 1}) #{failure['spec']}\n"
      log "    Failure/Error: #{failure['description']}\n", RED
      #log "    # #{failure['trace']}\n", CYAN
    end
    log "\n"
  end

  def output_from(line)
    json = JSON.parse(line)
    return false unless json['_teabag'] && json['type']
    case json['type']
      when "spec" then spec(json)
      when "error" then error(json)
      when "results" then results(json)
    end
    return true
  rescue JSON::ParserError => e
    false
  end

  def filename(file)
    file.gsub(%r(^http://127.0.0.1:\d+/assets/), "").gsub(/[\?|&]?body=1/, "")
  end

  def log(str, color_code = nil)
    STDOUT.print(color_code ? colorize(str, color_code) : str)
  end

  def colorize(str, color_code)
    "\e[#{color_code}m#{str}\e[0m"
  end
end