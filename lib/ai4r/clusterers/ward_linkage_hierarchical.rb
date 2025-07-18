# frozen_string_literal: true
# Author::    Peter Lubell-Doughtie
# License::   BSD 3 Clause
# Project::   ai4r
# Url::       http://peet.ldee.org

require_relative '../clusterers/ward_linkage'
require_relative '../clusterers/cluster_tree'

module Ai4r
  module Clusterers

    # Hierarchical version to store classes as merges occur.
    class WardLinkageHierarchical < WardLinkage

      include ClusterTree

      # @param depth [Object]
      # @return [Object]
      def initialize(depth = nil)
        @cluster_tree = []
        @depth = depth
        @merges_so_far = 0
        super()
      end

      # @param data_set [Object]
      # @param number_of_clusters [Object]
      # @param *options [Object]
      # @return [Object]
      def build(data_set, number_of_clusters = 1, **options)
        data_len = data_set.data_items.length
        @total_merges = data_len - number_of_clusters
        super
        @cluster_tree << self.clusters
        @cluster_tree.reverse!
        return self
      end

      # @return [Object]
      def supports_eval?
        false
      end

      protected

      # @param index_a [Object]
      # @param index_b [Object]
      # @param index_clusters [Object]
      # @return [Object]
      def merge_clusters(index_a, index_b, index_clusters)
        # only store if no or above depth
        if @depth.nil? or @merges_so_far > @total_merges - @depth
          # store current clusters
          stored_distance_matrix = @distance_matrix.dup
          @cluster_tree << build_clusters_from_index_clusters(index_clusters)
          @distance_matrix = stored_distance_matrix
        end
        @merges_so_far += 1
        super
      end
    end
  end
end
