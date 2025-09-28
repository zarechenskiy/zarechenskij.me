#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple static blog builder using Asciidoctor
# - Converts all .adoc files in content/ into HTML files in build/
# - Generates a minimal index.html linking to each generated post

require 'fileutils'
require 'asciidoctor'

CONTENT_DIR = File.expand_path('../content', __dir__).freeze
OUTPUT_DIR  = File.expand_path('../build', __dir__).freeze

FileUtils.mkdir_p OUTPUT_DIR

# Collect metadata for index
posts = []

adoc_files = Dir.glob(File.join(CONTENT_DIR, '**', '*.adoc')).sort

if adoc_files.empty?
  warn "No .adoc files found in #{CONTENT_DIR}. Create one, e.g., content/hello-world.adoc"
end

adoc_files.each do |src|
  # Load doc to get title/attributes without writing yet
  doc = Asciidoctor.load_file(src, safe: :safe)
  title = doc.doctitle || File.basename(src, '.adoc')

  # Determine output path mirroring subdirectories
  rel_path = src.delete_prefix(CONTENT_DIR + File::SEPARATOR)
  out_path = File.join(OUTPUT_DIR, rel_path.sub(/\.adoc\z/, '.html'))
  FileUtils.mkdir_p File.dirname(out_path)

  # Convert and write HTML
  Asciidoctor.convert_file(
    src,
    safe: :safe,
    to_file: out_path,
    attributes: {
      'toc' => 'left',
      'sectanchors' => '',
      'source-highlighter' => 'pygments',
      'stylesheet' => '', # use default built-in styles
    }
  )

  # Store metadata for index
  rel_link = out_path.delete_prefix(OUTPUT_DIR + File::SEPARATOR)
  posts << { title: title, link: rel_link }
end

# Generate a very simple index.html
index_html = <<~HTML
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Test Blog</title>
    <style>
      body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif; margin: 2rem; }
      h1 { font-size: 1.8rem; }
      ul { list-style: none; padding-left: 0; }
      li { margin: 0.5rem 0; }
      a { text-decoration: none; color: #0b5fff; }
      a:hover { text-decoration: underline; }
      footer { margin-top: 3rem; color: #666; font-size: 0.9rem; }
    </style>
  </head>
  <body>
    <h1>Test Blog</h1>
    <p>Generated with Asciidoctor.</p>
    <h2>Posts</h2>
    <ul>
      #{posts.map { |p| %(<li><a href="#{p[:link]}">#{p[:title]}</a></li>) }.join("\n      ")}
    </ul>
    <footer>
      <p>Generated at #{Time.now}</p>
    </footer>
  </body>
  </html>
HTML

File.write(File.join(OUTPUT_DIR, 'index.html'), index_html)

puts "Built #{posts.size} page(s) into #{OUTPUT_DIR}"