# frozen_string_literal: true
# Author::    Sergio Fierens
# License::   MPL 1.1
# Project::   ai4r
# Url::       https://github.com/SergioFierens/ai4r
#
# You can redistribute it and/or modify it under the terms of 
# the Mozilla Public License version 1.1  as published by the 
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt

require 'csv'
require 'set'
require_relative 'statistics'

module Ai4r
  module Data

    # A data set is a collection of N data items. Each data item is 
    # described by a set of attributes, represented as an array.
    # Optionally, you can assign a label to the attributes, using 
    # the data_labels property.
    class DataSet

      attr_reader :data_labels, :data_items

      # Return a new DataSet with numeric attributes normalized.
      # Available methods are:
      # * +:zscore+ - subtract the mean and divide by the standard deviation
      # * +:minmax+ - scale values to the [0,1] range
      # @param data_set [Object]
      # @param method [Object]
      # @return [Object]
      def self.normalized(data_set, method: :zscore)
        new_set = DataSet.new(
          data_items: data_set.data_items.map { |row| row.dup },
          data_labels: data_set.data_labels.dup
        )
        new_set.normalize!(method)
      end

      # Create a new DataSet. By default, empty.
      # Optionaly, you can provide the initial data items and data labels.
      # 
      # e.g. DataSet.new(:data_items => data_items, :data_labels => labels)
      # 
      # If you provide data items, but no data labels, the data set will
      # use the default data label values (see set_data_labels)
      # @param options [Object]
      # @return [Object]
      def initialize(options = {})
        @data_labels = []
        @data_items = options[:data_items] || []
        set_data_labels(options[:data_labels]) if options[:data_labels]
        set_data_items(options[:data_items]) if options[:data_items]
      end

      # Retrieve a new DataSet, with the item(s) selected by the provided 
      # index. You can specify an index range, too.
      # @param index [Object]
      # @return [Object]
      def [](index)
        selected_items = (index.is_a?(Integer)) ?
                [@data_items[index]] : @data_items[index]
        return DataSet.new(data_items: selected_items,
                           data_labels: @data_labels)
      end

      # Load data items from csv file
      # @param filepath [Object]
      # @return [Object]
      def load_csv(filepath, parse_numeric: false)
        if parse_numeric
          parse_csv(filepath)
        else
          items = []
          open_csv_file(filepath) do |entry|
            items << entry
          end
          set_data_items(items)
        end
      end

      # Open a CSV file and yield each row to the provided block.
      # @param filepath [Object]
      # @param block [Object]
      # @return [Object]
      def open_csv_file(filepath, &block)
        CSV.foreach(filepath) do |row|
          block.call row
        end
      end

      # Load data items from csv file. The first row is used as data labels.
      # @param filepath [Object]
      # @return [Object]
      def load_csv_with_labels(filepath, parse_numeric: false)
        load_csv(filepath, parse_numeric: parse_numeric)
        @data_labels = @data_items.shift
        return self
      end

      # Same as load_csv, but it will try to convert cell contents as numbers.
      # @param filepath [Object]
      # @return [Object]
      def parse_csv(filepath)
        items = []
        open_csv_file(filepath) do |row|
          items << row.collect do |x|
            is_number?(x) ? Float(x, exception: false) : x
          end
        end
        set_data_items(items)
      end

      # Same as load_csv_with_labels, but it will try to convert cell contents as numbers.
      # @param filepath [Object]
      # @return [Object]
      def parse_csv_with_labels(filepath)
        load_csv_with_labels(filepath, parse_numeric: true)
      end

      # Set data labels.
      # Data labels must have the following format:
      #     [ 'city', 'age_range', 'gender', 'marketing_target'  ]
      #
      # If you do not provide labels for you data, the following labels will
      # be created by default:
      #     [ 'attribute_1', 'attribute_2', 'attribute_3', 'class_value'  ]      
      # @param labels [Object]
      # @return [Object]
      def set_data_labels(labels)
        check_data_labels(labels)
        @data_labels = labels
        return self
      end

      # Set the data items.
      # M data items with  N attributes must have the following 
      # format:
      # 
      #     [   [ATT1_VAL1, ATT2_VAL1, ATT3_VAL1, ... , ATTN_VAL1,  CLASS_VAL1], 
      #         [ATT1_VAL2, ATT2_VAL2, ATT3_VAL2, ... , ATTN_VAL2,  CLASS_VAL2], 
      #         ...
      #         [ATTM1_VALM, ATT2_VALM, ATT3_VALM, ... , ATTN_VALM, CLASS_VALM], 
      #     ]
      #     
      # e.g.
      #     [   ['New York',  '<30',      'M', 'Y'],
      #          ['Chicago',     '<30',      'M', 'Y'],
      #          ['Chicago',     '<30',      'F', 'Y'],
      #          ['New York',  '<30',      'M', 'Y'],
      #          ['New York',  '<30',      'M', 'Y'],
      #          ['Chicago',     '[30-50)',  'M', 'Y'],
      #          ['New York',  '[30-50)',  'F', 'N'],
      #          ['Chicago',     '[30-50)',  'F', 'Y'],
      #          ['New York',  '[30-50)',  'F', 'N'],
      #          ['Chicago',     '[50-80]', 'M', 'N'],
      #          ['New York',  '[50-80]', 'F', 'N'],
      #          ['New York',  '[50-80]', 'M', 'N'],
      #          ['Chicago',     '[50-80]', 'M', 'N'],
      #          ['New York',  '[50-80]', 'F', 'N'],
      #          ['Chicago',     '>80',      'F', 'Y']
      #        ]
      # 
      # This method returns the classifier (self), allowing method chaining.
      # @param items [Object]
      # @return [Object]
      def set_data_items(items)
        check_data_items(items)
        @data_labels = default_data_labels(items) if @data_labels.empty?
        @data_items = items
        return self
      end

      # Returns an array with the domain of each attribute:
      # * Set instance containing all possible values for nominal attributes
      # * Array with min and max values for numeric attributes (i.e. [min, max])
      # 
      # Return example:
      # => [#<Set: {"New York", "Chicago"}>, 
      #     #<Set: {"<30", "[30-50)", "[50-80]", ">80"}>, 
      #     #<Set: {"M", "F"}>,
      #     [5, 85], 
      #     #<Set: {"Y", "N"}>]
      # @return [Object]
      def build_domains
        @data_labels.collect {|attr_label| build_domain(attr_label) }
      end

      # Returns a Set instance containing all possible values for an attribute
      # The parameter can be an attribute label or index (0 based).
      # * Set instance containing all possible values for nominal attributes
      # * Array with min and max values for numeric attributes (i.e. [min, max])
      # 
      #   build_domain("city")
      #   => #<Set: {"New York", "Chicago"}>
      #   
      #   build_domain("age")
      #   => [5, 85]
      # 
      #   build_domain(2) # In this example, the third attribute is gender
      #   => #<Set: {"M", "F"}>
      # @param attr [Object]
      # @return [Object]
      def build_domain(attr)
        index = get_index(attr)
        if @data_items.first[index].is_a?(Numeric)
          return [Statistics.min(self, index), Statistics.max(self, index)]
        else
          return @data_items.inject(Set.new){|domain, x| domain << x[index]}
        end
      end

      # Returns attributes number, including class attribute
      # @return [Object]
      def num_attributes
        return (@data_items.empty?) ? 0 : @data_items.first.size
      end

      # Returns the index of a given attribute (0-based).
      # For example, if "gender" is the third attribute, then:
      #   get_index("gender") 
      #   => 2
      # @param attr [Object]
      # @return [Object]
      def get_index(attr)
        return (attr.is_a?(Integer) || attr.is_a?(Range)) ? attr : @data_labels.index(attr)
      end

      # Raise an exception if there is no data item.
      # @return [Object]
      def check_not_empty
        if @data_items.empty?
          raise ArgumentError, "Examples data set must not be empty."
        end
      end

      # Add a data item to the data set
      # @return [Object]
      def << data_item
        if data_item.nil? || !data_item.is_a?(Enumerable) || data_item.empty?
          raise ArgumentError, "Data must not be an non empty array."
        elsif @data_items.empty?
          set_data_items([data_item])
        elsif data_item.length != num_attributes
          raise ArgumentError, "Number of attributes do not match. " +
                  "#{data_item.length} attributes provided, " +
                  "#{num_attributes} attributes expected."
        else
          @data_items << data_item
        end
      end

      # Returns an array with the mean value of numeric attributes, and 
      # the most frequent value of non numeric attributes
      # @return [Object]
      def get_mean_or_mode
        mean = []
        num_attributes.times do |i|
          mean[i] =
                  if @data_items.first[i].is_a?(Numeric)
                    Statistics.mean(self, i)
                  else
                    Statistics.mode(self, i)
                  end
        end
        return mean
      end

      # Normalize numeric attributes in place. Supported methods are
      # +:zscore+ (default) and +:minmax+.
      # @param method [Object]
      # @return [Object]
      def normalize!(method = :zscore)
        numeric_indices = (0...num_attributes).select do |i|
          @data_items.first[i].is_a?(Numeric)
        end

        case method
        when :zscore
          means = numeric_indices.map { |i| Statistics.mean(self, i) }
          sds = numeric_indices.map { |i| Statistics.standard_deviation(self, i) }
          @data_items.each do |row|
            numeric_indices.each_with_index do |idx, j|
              sd = sds[j]
              row[idx] = sd.zero? ? 0 : (row[idx] - means[j]) / sd
            end
          end
        when :minmax
          mins = numeric_indices.map { |i| Statistics.min(self, i) }
          maxs = numeric_indices.map { |i| Statistics.max(self, i) }
          @data_items.each do |row|
            numeric_indices.each_with_index do |idx, j|
              range = maxs[j] - mins[j]
              row[idx] = range.zero? ? 0 : (row[idx] - mins[j]) / range.to_f
            end
          end
        else
          raise ArgumentError, "Unknown normalization method #{method}"
        end

        self
      end

      # Randomizes the order of data items in place.
      # If a +seed+ is provided, it is used to initialize the random number
      # generator for deterministic shuffling.
      #
      #   data_set.shuffle!(seed: 123)
      #
      # @param seed [Integer, nil] Seed for the RNG
      # @return [DataSet] self
      def shuffle!(seed: nil)
        rng = seed ? Random.new(seed) : Random.new
        @data_items.shuffle!(random: rng)
        self
      end

      # Split the dataset into two new DataSet instances using the given ratio
      # for the first set.
      #
      #   train, test = data_set.split(ratio: 0.8)
      #
      # @param ratio [Float] fraction of items to place in the first set
      # @return [Array<DataSet, DataSet>] the two resulting datasets
      def split(ratio:)
        raise ArgumentError, 'ratio must be between 0 and 1' unless ratio.positive? && ratio < 1

        pivot = (ratio * @data_items.length).round
        first_items = @data_items[0...pivot].map { |row| row.dup }
        second_items = @data_items[pivot..-1].map { |row| row.dup }

        [
          DataSet.new(data_items: first_items, data_labels: @data_labels.dup),
          DataSet.new(data_items: second_items, data_labels: @data_labels.dup)
        ]
      end

      # Returns label of category
      # @return [Object]
      def category_label
        data_labels.last
      end

      protected

      # @param x [Object]
      # @return [Object]
      def is_number?(x)
        !Float(x, exception: false).nil?
      end

      # @param data_items [Object]
      # @return [Object]
      def check_data_items(data_items)
        if !data_items || data_items.empty?
          raise ArgumentError, "Examples data set must not be empty."
        elsif !data_items.first.is_a?(Enumerable)
          raise ArgumentError, "Unkown format for example data."
        end
        attributes_num = data_items.first.length
        data_items.each_index do |index|
          if data_items[index].length != attributes_num
            raise ArgumentError,
                  "Quantity of attributes is inconsistent. " +
                          "The first item has #{attributes_num} attributes "+
                          "and row #{index} has #{data_items[index].length} attributes"
          end
        end
      end

      # @param labels [Object]
      # @return [Object]
      def check_data_labels(labels)
        if !@data_items.empty?
          if labels.length != @data_items.first.length
            raise ArgumentError,
                  "Number of labels and attributes do not match. " +
                          "#{labels.length} labels and " +
                          "#{@data_items.first.length} attributes found."
          end
        end
      end

      # @param data_items [Object]
      # @return [Object]
      def default_data_labels(data_items)
        data_labels = []
        data_items[0][0..-2].each_index do |i|
          data_labels[i] = "attribute_#{i+1}"
        end
        data_labels[data_labels.length]="class_value"
        return data_labels
      end

    end
  end
end
