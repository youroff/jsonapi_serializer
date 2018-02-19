require './perf/models'
require 'benchmark'
require 'digest'

class Runner

  WIDTH = 20

  def initialize(count)
    @repo = Models.new(count)
  end

  def set_modules(*modules)
    @modules = modules
  end

  def set_tests(*tests)
    @tests = tests
  end

  def set_takes(*takes)
    @takes = takes
  end

  def run
    @results = {}
    @tests.each do |test_case|
      @results[test_case] = {takes: @takes, times: [], digests: {}}
      @modules.each do |mod|
        mod_results = [mod.to_s]
        if mod.respond_to? test_case
          @takes.each do |count|
            records = @repo.take(count)
            hash = '%.2f' % (Benchmark.measure { mod.send(test_case, records, :hash) }.real * 1000)
            output = nil
            json = '%.2f' % (Benchmark.measure { output = mod.send(test_case, records, :json) }.real * 1000)
            verify_digest(count, @results[test_case][:digests], Digest::MD5.hexdigest(output))
            mod_results << "#{hash} / #{json}"
          end
        else
          mod_results += Array.new(@takes.length, "-")
        end
        @results[test_case][:times] << mod_results
      end
    end
  end

  def print_table(test_case)
    print_header(@results[test_case][:takes])
    print_body(@results[test_case][:times])
  end

  def print_header(takes)
    col_titles = takes.map do |count|
      "#{count} hash/json (ms)".center(WIDTH)
    end
    headers = ["Adapters".center(WIDTH)] + col_titles
    print "| " + headers.join(" | ") + " |\n"
    print "| " + Array.new(headers.length, "".rjust(WIDTH, "-")).join(" | ") + " |\n"
  end

  def print_body(times)
    times.each do |ts|
      print "| " + ts.map { |t| t.center(WIDTH) }.join(" | ") + " |\n"
    end
  end

  def verify_digest(count, tracker, digest)
    current = tracker[count]
    if current.nil?
      tracker[count] = digest
    elsif current != digest
      tracker[count] = false
    end
  end
end
