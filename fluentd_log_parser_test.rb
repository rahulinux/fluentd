#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# For testing custom regex for custom log format 
 
require 'time'
require 'fluent/log'
require 'fluent/config'
require 'fluent/engine'
require 'fluent/parser'
 
$log ||= Fluent::Log.new
 
# debug
log = "2014-09-18T12:23:31.832Z - error: START Property 'log' of object function (req, res, next) {
    app.handle(req, res, next);
  } is not a function 
TypeError: Property 'log' of object function (req, res, next) {
    app.handle(req, res, next);
  } is not a function
    at ServerResponse.<anonymous> (/roshan/api/cs-api/contentstack-api/framework/middleware/request-logger.js:21:21)
    at ServerResponse.emit (events.js:117:20)
    at ServerResponse.OutgoingMessage._finish (http.js:1016:8)
    at ServerResponse.OutgoingMessage.end (http.js:999:10)
    at Gzip.<anonymous> (/roshan/api/cs-api/contentstack-api/node_modules/compression/index.js:209:13)
    at Gzip.emit (events.js:117:20)
    at _stream_readable.js:938:16
    at process._tickDomainCallback (node.js:463:13) END
2014-09-18T12:23:31.832Z - error: START Property 'log' of object function (req, res, next) "

format = /^(?<time>[^ ]+ [^ ]+) (?<log_level>error:) (?<message>(.|\n)*)\n/
time_format = ''
 
parser = Fluent::TextParser::RegexpParser.new(format, 'time_format' => time_format)
puts parser.call(log)
