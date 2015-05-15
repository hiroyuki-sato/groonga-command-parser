# -*- coding: utf-8 -*-
#
# Copyright (C) 2011-2015  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require 'json'
require 'json/stream'
require 'groonga/command/json-stream-extension'

module Groonga
  module Command

    # A parser listener that builds a full, in memory, object from a JSON
    # document. This is similar to using the json gem's `JSON.parse` method.
    #
    # Examples
    #
    #   parser = JSON::Stream::Parser.new
    #   builder = JSON::Stream::Builder.new(parser)
    #   parser << '{"answer": 42, "question": false}'
    #   obj = builder.result
    class JSONBuilder
      METHODS = %w[start_document end_document start_object end_object start_array end_array key value]

      attr_reader :result

      def initialize(parser)
        @parser = parser
        METHODS.each do |name|
          parser.send(name, &method(name))
        end
        @callbacks = []
      end

      def on_parse_complete=(block)
        @callbacks.push block
      end

      def start_document
        @stack = []
        @keys = []
        @result = nil
      end

      def end_document
        @result = @stack.pop
        @callbacks.each { |c| c.call @result }
        @parser.reset
        @result
      end

      def start_object
        @stack.push({})
      end

      def end_object
        return if @stack.size == 1

        node = @stack.pop
        top = @stack[-1]

        case top
        when Hash
          top[@keys.pop] = node
        when Array
          top << node
        end
      end
      alias :end_array :end_object

      def start_array
        @stack.push([])
      end

      def key(key)
        @keys << key
      end

      def value(value)
        top = @stack[-1]
        case top
        when Hash
          top[@keys.pop] = value
        when Array
          top << value
        else
          @stack << value
        end
      end
    end

  end
end
