#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple static blog builder using Asciidoctor
# - Converts all .adoc files in content/ into HTML files in build/
# - Generates a nicer index.html with About, Posts, and Talks

require 'fileutils'
require 'asciidoctor'
require 'json'
require 'time'

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
  revdate_attr = doc.attr('revdate') || doc.attr('revdate-at')
  # Parse date if present; fall back to file mtime
  date = begin
    Time.parse(revdate_attr.to_s)
  rescue StandardError
    File.mtime(src)
  end

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
      'docinfo' => 'shared', # inject content/docinfo.html
    }
  )

  # Store metadata for index
  rel_link = out_path.delete_prefix(OUTPUT_DIR + File::SEPARATOR)
  posts << { title: title, link: rel_link, date: date }
end

posts.sort_by! { |p| p[:date] || Time.at(0) }
posts.reverse!

about_path = File.join(CONTENT_DIR, 'about.html')
about_html = File.read(about_path)

Talk = Struct.new(:title, :url, :event, :date, keyword_init: true)

talks = []

talks_path = File.join(CONTENT_DIR, 'talks.json')
if File.exist?(talks_path)
  begin
    data = JSON.parse(File.read(talks_path))
    data.each do |t|
      talks << Talk.new(
        title: t['title'],
        url:   t['url'],
        event: t['event'],
        date:  t['date']
      )
    end
  rescue JSON::ParserError => e
    warn "Failed to parse talks.json: #{e.message}"
  end
end

now = Time.now
index_html = <<~HTML
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>zarechenskij.me</title>
    <style>
      :root {
        --bg: #0b0e14;
        --surface: #111827;
        --text: #e5e7eb;
        --muted: #9ca3af;
        --link: #60a5fa;
        --accent: #22d3ee;
        --card: #0f172a;
      }
      @media (prefers-color-scheme: light) {
        :root {
          --bg: #fafafa; --surface: #ffffff; --text: #111827; --muted: #6b7280; --link: #1d4ed8; --accent: #0891b2; --card: #ffffff;
        }
      }
      * { box-sizing: border-box; }
      body { margin: 0; background: var(--bg); color: var(--text); font: 16px/1.6 system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif; }
      .container { max-width: 860px; margin: 0 auto; padding: 2rem 1rem; }
      header { display: flex; align-items: baseline; justify-content: space-between; gap: 1rem; margin-bottom: 1.5rem; }
      header h1 { font-size: 1.8rem; margin: 0; }
      header .tagline { color: var(--muted); font-size: 1rem; }
      .card { background: var(--card); border: 1px solid rgba(255,255,255,0.06); border-radius: 12px; padding: 1rem 1.25rem; box-shadow: 0 1px 2px rgba(0,0,0,0.05); }
      .grid { display: grid; grid-template-columns: 1fr; gap: 1rem; }
      @media (min-width: 880px) { .grid { grid-template-columns: 1.2fr 0.8fr; } }
      h2 { font-size: 1.2rem; margin: 0 0 0.75rem; }
      a { color: var(--link); text-decoration: none; }
      a:hover { text-decoration: underline; }
      ul.reset { list-style: none; padding: 0; margin: 0; }
      li.item { padding: 0.4rem 0; border-bottom: 1px solid rgba(255,255,255,0.06); }
      li.item:last-child { border-bottom: none; }
      .meta { color: var(--muted); font-size: 0.9rem; }
      footer { margin-top: 2rem; color: var(--muted); font-size: 0.9rem; text-align: center; }
    </style>
  </head>
  <body>
    <div class="container">
      <header>
        <h1>zarechenskij.me</h1>
        <div class="tagline">Thoughts on Kotlin, language design, and more</div>
      </header>
      <div class="grid">
        <section class="card" id="about" style="grid-column: 1 / -1;">
          <h2>About</h2>
          #{about_html}
        </section>
        <section class="card" id="posts" style="grid-column: 1 / -1;">
          <h2>Posts</h2>
          <ul class="reset">
            #{posts.map { |p|
              date = p[:date]
              date_str = date ? date.strftime('%Y-%m-%d') : ''
              %(<li class="item"><a href="#{p[:link]}">#{p[:title]}</a> <span class="meta">#{date_str}</span></li>)
            }.join("\n            ")}
          </ul>
        </section>
        <section class="card" id="talks" style="grid-column: 1 / -1;">
          <h2>Talks & Videos</h2>
          #{%(<ul class="reset">\n            #{talks.map { |t|
              date_str = t.date ? %(<span class="meta"> · #{t.date}</span>) : ''
              event_str = t.event ? %(<span class="meta"> · #{t.event}</span>) : ''
              %(<li class="item"><a href="#{t.url}">#{t.title}</a>#{event_str}#{date_str}</li>)
            }.join("\n            ")}\n          </ul>)}
        </section>
      </div>
      <footer>
        <p>Generated at #{now.strftime('%Y-%m-%d %H:%M %Z')}</p>
      </footer>
    </div>
  </body>
  </html>
HTML

File.write(File.join(OUTPUT_DIR, 'index.html'), index_html)

puts "Built #{posts.size} page(s) into #{OUTPUT_DIR}"