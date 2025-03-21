#!/usr/bin/env ruby
## frozen_string_literal: true
require 'yaml'

PATHS = YAML.load_file('config.yml')['Paths']

check_file  = ->(leaf) { contents = File.read(leaf) ; contents.include?('<li>[ ]') ? true : false }
list_md     = ->{ Dir.children('.').select { |l| l.end_with? '.md' } }
themes      = ->{ Dir.children('lib').select{|l| l.match(/css$/)}.map{|n| n.split('.')[0]} }

def convert(file:, style:)
  require 'commonmarker'
  require 'github/markup'

  @leaf      = file
  @style   ||= style
  page_name  = "#{file.split('.')[0]}.html"
  conversion = GitHub::Markup.render(file, File.read(file))

  File.write(
    page_name,
    "<head>\n<link rel='stylesheet' type='text/css' href='lib/#{@style}.css' />\n</head>\n\n<body>",
    mode: 'wb'
  )
  
  if conversion.include?('<li>[ ]')
    conversion = substitute_checks(conversion)
  end

  File.write(page_name, conversion, mode: 'a')
  File.write(page_name, "\n</body>", mode: 'a')
  puts page_name
end

def get_stubs  # Populate html templates to be inserted
  @stubs ||= Hash.new

  Dir.children(PATHS[:stubs]).select{|s| s.end_with?('.html')}.each do |leaf|
    @stubs.merge!({ leaf.gsub(/\.html$/,'').to_sym => File.read("#{PATHS[:stubs]}/#{leaf}") })
  end
end

def substitute_checks(content)
  lines     = content.split(/\n/).each_with_index.map{|l,ldx| [ldx,l]}
  regex     = /\<li\>\[\s\].+\<\/li\>/
  sub_list  = lines.select{|l| l[1].match?(regex)}
  ul_ends   = [sub_list.last.first + 1, sub_list.first.first - 1]
  checklist = sub_list.map{|e| e[1].gsub(/\<li\>\[\s\]\s/, '').gsub(/\<\/li\>/, '')}

  sub_list.each_with_index do |ele, edx|
    ## ele = [12, '<li>[ ] First Check Box</li>'] => [line_of_file, content_to_be_subbed]

    lines[ele[0]][1].gsub!(ele[1], checkbox_subber(checklist[edx]))
  end

  ul_ends.each{|ldx| lines.delete_at(ldx)}
  if lines[ul_ends.last - 1][1].match?('/ol')
    after = sub_list.last.first - 1
    puts("after: #{after}")
    lines.delete_at(ul_ends.last - 1)
    lines.insert(after, [after, "</ol>"])
    puts("moved /ol: [#{after}, [#{after}, '</ol>']]")
  end

  pp lines
  return lines.map{|l| l[1]}.join("\n")
end

def checkbox_subber(label)
  @cbdx  ||= 0
  @stubs ||  get_stubs

  subbed = @stubs[:checkbox].gsub('ID', "checkbox_#{@cbdx}").gsub('LABEL', label)
  @cbdx += 1

  return subbed
end

case ARGV.count
when 0
  list_md.call.each{ |md| convert file: md, style: 'default' }
when 1
  if themes.call.include? ARGV[0]
    list_md.call.each{ |md| convert file: md, style: ARGV[0] }
  else
    convert file: ARGV[0], style: 'default'
  end
when 2
  convert file: ARGV[0], style: ARGV[1]
else
  puts "\033[38;5;160mExpected 0-2 arguments, but got #{ARGV.count}\033[0m"
end
