#!/usr/bin/env ruby
## frozen_string_literal: true

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
  File.write(page_name, conversion, mode: 'a')
  File.write(page_name, "\n</body>", mode: 'a')
  puts page_name
end

def list_md
  Dir.children('.').select { |l| l.end_with? '.md' }
end

def themes
  Dir.children('lib').select{|l| l.match(/css$/)}.map{|n| n.split('.')[0]}
end

case ARGV.count
when 0
  list_md.each{ |md| convert file: md, style: 'default' }
when 1
  if themes.include? ARGV[0]
    list_md.each{ |md| convert file: md, style: ARGV[0] }
  else
    convert file: ARGV[0], style: 'default'
  end
when 2
  convert file: ARGV[0], style: ARGV[1]
else
  puts "\033[38;5;160mExpected 0-2 arguments, but got #{ARGV.count}\033[0m"
end
