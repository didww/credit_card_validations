require 'coverage'
Coverage.start(lines: true)

LIB_ROOT = File.expand_path('../lib', __dir__)
COVERAGE_DIR = File.expand_path('../coverage', __dir__)

at_exit do
  result = Coverage.result
  lib_results = result.select { |path, _| path.start_with?(LIB_ROOT + '/') }

  total = 0
  covered = 0
  lib_results.each_value do |data|
    data[:lines].each do |hits|
      next if hits.nil?
      total += 1
      covered += 1 if hits > 0
    end
  end

  pct = total.zero? ? 0.0 : (covered * 100.0 / total)
  pct_rounded = pct.round(1)

  Dir.mkdir(COVERAGE_DIR) unless Dir.exist?(COVERAGE_DIR)

  File.write(
    File.join(COVERAGE_DIR, 'summary.txt'),
    "Coverage: #{pct_rounded}% (#{covered}/#{total} lines)\n"
  )

  color = case pct
          when 90..100 then '#4c1'
          when 75...90 then '#97CA00'
          when 60...75 then '#dfb317'
          when 40...60 then '#fe7d37'
          else '#e05d44'
          end

  label = 'coverage'
  value = "#{pct_rounded}%"
  label_w = 6 * label.length + 20
  value_w = 7 * value.length + 10
  total_w = label_w + value_w

  svg = <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="#{total_w}" height="20" role="img" aria-label="coverage: #{value}">
      <linearGradient id="s" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
        <stop offset="1" stop-opacity=".1"/>
      </linearGradient>
      <clipPath id="r"><rect width="#{total_w}" height="20" rx="3" fill="#fff"/></clipPath>
      <g clip-path="url(#r)">
        <rect width="#{label_w}" height="20" fill="#555"/>
        <rect x="#{label_w}" width="#{value_w}" height="20" fill="#{color}"/>
        <rect width="#{total_w}" height="20" fill="url(#s)"/>
      </g>
      <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
        <text x="#{label_w / 2.0}" y="14">#{label}</text>
        <text x="#{label_w + value_w / 2.0}" y="14">#{value}</text>
      </g>
    </svg>
  SVG

  File.write(File.join(COVERAGE_DIR, 'badge.svg'), svg)

  puts "Coverage: #{pct_rounded}% (#{covered}/#{total} lines)"
  puts "Badge written to #{File.join(COVERAGE_DIR, 'badge.svg')}"
end

spec_dir = File.expand_path('../spec', __dir__)
$LOAD_PATH.unshift(spec_dir)
Dir.glob(File.join(spec_dir, '*_spec.rb')).sort.each { |f| require f }
