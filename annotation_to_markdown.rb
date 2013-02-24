#!/usr/bin/env ruby
# encoding: utf-8

gem "nokogiri", "~> 1.5.6"
gem "activesupport", "~> 3.2.12"

require "rubygems"
require "find"
require "nokogiri"
require "yaml"
require "active_support/core_ext/string/inflections.rb"
require "active_support/inflector/transliterate"
include ActiveSupport::Inflector
require "date"

# Configuration
#XML_DIRECTORY = "/media/Cybook/Digital Editions/Annotations/Digital Editions/"
XML_DIRECTORY = "Digital Editions"
MD_DIRECTORY = "markdown-annotations"
MD_TEMPLATE = <<EOF
---
layout: quote
fragment_start: %{fragment_start}
fragment_end: %{fragment_end}
category: Quote
---

%{text}
EOF

# Support template variables in Ruby < 1.9.2
if RUBY_VERSION < '1.9.2'
  class String
    old_format = instance_method(:%)
    define_method(:%) do |arg|
      if arg.is_a?(Hash)
        self.gsub(/%\{(.*?)\}/) { arg[$1.to_sym] }
      else
        old_format.bind(self).call(arg)
      end
    end
  end
end

module Find
  def self.find_by_pattern dir, pattern
    Find.find dir do |path|
      if FileTest.directory?(path)
        if File.basename(path)[0] == "."
          Find.prune
        else
          next
        end
      else
        if File.basename(path) !~ pattern
          Find.prune
        end
        if block_given?
          yield path
        end
      end
    end
  end
end

class AnnotationToMarkdown
  def self.process directory
    Find.find_by_pattern directory, /\.epub\.annot$/ do |path|
      annotations_file = EpubAnnotationsFile.new path
      annotations_file.save_new_annotations
    end
  end
end

class EpubAnnotationsFile
  def initialize path
    @path = path
    @title = File.basename @path, ".epub.annot"
    @title_param = @title.parameterize
    @annotations = annotations
    @md_annotations = md_annotations
  end

  def save_new_annotations
    counter = @md_annotations.count
    (@annotations - @md_annotations).select { |a| a.is_a? Annotation }.each do |a|
      counter += 1
      annotation = a.to_markdown :title => @title_param, :counter => counter
      annotation.write
    end
  end

  private

  def annotations
    xml = nil
    File.open @path do |file|
      xml = Nokogiri::XML file
    end
    annotations = []
    xml.css("annotation").each do |node|
      annotations << XmlAnnotation.new(node)
    end
    return annotations
  end

  def md_annotations
    annotations = []
    Find.find_by_pattern MD_DIRECTORY, /^\d{4}-\d{2}-\d{2}-#{@title_param}-\d*\.md$/ do |path|
      annotations << MarkdownAnnotation.read(path)
    end
    return annotations
  end
end

class Annotation
  attr_reader :date, :title, :counter, :start, :end, :text

  def ==(other)
    @start == other.start && @end == other.end
  end

  alias eql? ==

  def hash
    @start.hash ^ @end.hash
  end
end

class XmlAnnotation < Annotation
  def initialize node
    @start = node.css("fragment")[0]["start"].gsub /.*point\((.*)\)/, '\1'
    @end = node.css("fragment")[0]["end"].gsub /.*point\((.*)\)/, '\1'
    @text = node.css("text").children.to_xml(:encoding => "UTF-8").to_s.strip
  end

  def to_markdown args
    @title = args[:title]
    @counter = args[:counter]
    MarkdownAnnotation.new self
  end
end

class MarkdownAnnotation < Annotation
  def initialize annotation
    if annotation.is_a? Annotation
      @title = annotation.title
      @start = annotation.start
      @end = annotation.end
      @text = annotation.text
      @date = Time.now.strftime "%Y-%m-%d"
      @filename = [ @date, @title, annotation.counter ].join("-") + ".md"
    else
      @path = annotation
      @basename = File.basename @path, ".md"
      @date, @title = @basename.match(/^(\d{4}-\d{2}-\d{2})-(.*)-\d*$/).captures
      read_annotation
    end
  end

  def self.read path
    self.new path
  end

  def write
    if @path.nil?
      File.open "#{MD_DIRECTORY}/#{@filename}", "w" do |file|
        file << MD_TEMPLATE % { :text => @text, :fragment_start => @start, :fragment_end => @end }
      end
    end
  end

  private

  def read_annotation
    file = File.open @path
    yaml_front_matter, @text = file.read.match(/^-{3}\n([^-]*)-{3}\n(.*)/m).captures
    yaml = YAML.load yaml_front_matter
    @start = yaml["fragment_start"]
    @end = yaml["fragment_end"]
  end
end

AnnotationToMarkdown.process XML_DIRECTORY
