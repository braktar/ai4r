# Author::    Sergio Fierens
# License::   MPL 1.1
# Project::   ai4r
# Url::       https://github.com/SergioFierens/ai4r
#
# You can redistribute it and/or modify it under the terms of 
# the Mozilla Public License version 1.1  as published by the 
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt
 
require 'ai4r/genetic_algorithm/genetic_algorithm'
require 'ai4r/genetic_algorithm/tsp_chromosome'
require 'minitest/autorun'

module Ai4r
  
  module GeneticAlgorithm

  COUNTRY = %w"Belgium France Germany Ireland Italy Poland Portugal Spain Sweden UK"

   #         Belgium,  France,   Germany,  Ireland,  Italy,  Poland,   Portugal,   Spain,  Sweden,   UK
  COSTS = [
              [  0,       10,       12,       21,       25,     25,       34,         26,     28,       11],
              [ 10,       0,        12,       21,       19,     21,       18,         12,     22,       11],
              [ 10,       12,       0,        24,       18,     16,       36,         29,     17,       22],
              [ 20,       12,       22,       0,        32,     34,       28,         24,     31,        9],
              [ 23,       20,       19,       31,        0,     25,       29,         25,     31,       28],
              [ 24,       20,       15,       33,       24,      0,       38,         34,     17,       25],
              [ 33,       19,       35,       29,       24,     34,        0,          9,     38,       28],
              [ 25,       13,       28,       25,       25,     34,        9,          0,     33,       19],
              [ 30,       23,       18,       29,       31,     18,       38,         34,      0,       23],
              [ 11,       11,       22,       9,        28,     26,       27,         19,     22,        0]
  ]


    class GeneticAlgorithmTest < Minitest::Test

      def test_chromosome_seed
        TspChromosome.set_cost_matrix(COSTS)
        chromosome = TspChromosome.seed
        assert_equal [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], chromosome.data.sort
      end

      def test_fitness
        TspChromosome.set_cost_matrix(COSTS)
        chromosome = TspChromosome.new([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        assert_equal( -206, chromosome.fitness)
      end

      def test_selection
        search = GeneticSearch.new(10, 5, TspChromosome)
        search.generate_initial_population
        selected =  search.selection
        selected.each { |c| assert c!=nil }
        assert_equal 6, selected.length
        assert_equal 1, search.population[0].normalized_fitness
        assert_equal 0, search.population.last.normalized_fitness
        assert_equal 10, search.population.length
      end

      def test_reproduction
        search = GeneticSearch.new(10, 5, TspChromosome)
        search.generate_initial_population
        selected =  search.selection
        offsprings = search.reproduction selected
        assert_equal 3, offsprings.length
      end    

      def test_replace_worst_ranked
        search = GeneticSearch.new(10, 5, TspChromosome)
        search.generate_initial_population
        selected =  search.selection
        offsprings = search.reproduction selected
        search.replace_worst_ranked offsprings
        assert_equal 10, search.population.length
        offsprings.each { |c| assert search.population.include?(c)}
      end

      def test_on_generation_callback
        TspChromosome.set_cost_matrix(COSTS)
        gens = []
        search = GeneticSearch.new(10, 2, TspChromosome, 0.3, 0.4, nil, nil,
                                   lambda { |g, f| gens << g })
        search.run
        assert gens.include?(0)
        assert gens.max <= 2
      end

      def test_fitness_threshold
        TspChromosome.set_cost_matrix(COSTS)
        search = GeneticSearch.new(10, 5, TspChromosome, 0.3, 0.4, -1_000_000)
        search.run
        assert_equal 1, search.instance_variable_get(:@generation)
      end

      def test_max_stagnation
        TspChromosome.set_cost_matrix(COSTS)
        search = GeneticSearch.new(10, 5, TspChromosome, 0.3, 0.4, nil, 0)
        search.run
        assert_equal 1, search.instance_variable_get(:@generation)
      end

    end

  end

end
