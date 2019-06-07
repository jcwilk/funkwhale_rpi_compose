#!/usr/bin/env ruby

require 'fileutils'

#https://docs.docker.com/compose/compose-file/#variable-substitution
#Balena doesn't support compose substitution so we'll do it ourselves!

mapping = {}
count = 0
File.open("./.env") do |f|
  f.each_line do |line|
    count+=1
    stripped_line = line.strip.gsub(/^#.*$/,'')
    if !stripped_line.empty?
      k,v=stripped_line.split('=')
      raise "#{stripped_line.inspect} ##{count} failed!" if k.nil? || k.empty?
      if !v.nil? && !v.empty?
        mapping[k] = v
      end
    end
  end
end

count = 0
File.open("./docker-compose.yml.og") do |f|
  tmp = File.open('./docker-compose.yml.tmp','w')
  f.each_line do |line|
    count+=1

    next if line.strip =~ /^#/
    tmp << line.gsub(/\$\{([^}]*)\}/) do |match|
      contents = $1
      if contents =~ /:-/
        key,default = contents.split(":-")
        if !mapping.key?(key) || mapping[key].empty?
          default
        else
          mapping[key]
        end
      elsif contents =~ /-/
        key,default = contents.split("-")
        if !mapping.key?(key)
          default
        else
          mapping[key]
        end
      elsif contents =~ /^[A-Z][A-Z_]*$/
        mapping[contents]
      else
        raise "unable to parse #{contents.inspect} ##{count}"
      end
    end
  end

  tmp.close
  FileUtils.mv('docker-compose.yml.tmp','docker-compose.yml')
end
