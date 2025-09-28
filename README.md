# Simple Asciidoctor Blog

This repository contains a minimal static blog generator written in Ruby. It converts AsciiDoc (`.adoc`) files from the `content/` directory into HTML files in the `build/` directory using Asciidoctor, and creates a simple `index.html` that links to each post.

## Prerequisites
- Ruby 3.x (see Gemfile for supported range)
- Bundler (`gem install bundler`) if you want to run via `bundle exec`

## Install dependencies
```
bundle install
```

## Add content
A sample post is provided at `content/hello-world.adoc`.

To add new posts, create more `.adoc` files under the `content/` directory. Example:
```
content/my-second-post.adoc
```
With the contents like:
```
= My Second Post
Your Name

This is another post written in AsciiDoc.
```

## Build the site
You can build the blog with:
```
ruby scripts/build.rb
# or
bundle exec ruby scripts/build.rb
```

The generated site will be in the `build/` directory:
- `build/index.html` – index page listing all posts
- `build/hello-world.html` – generated HTML for the sample post

## Notes
- Syntax highlighting is enabled via `pygments.rb` (set as Asciidoctor `source-highlighter`).
- The generated HTML uses Asciidoctor's default stylesheet for simplicity.
