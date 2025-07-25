# frozen_string_literal: true
# Author::    Sergio Fierens (implementation)
# License::   MPL 1.1
# Project::   ai4r
# Url::       https://github.com/SergioFierens/ai4r
#
# You can redistribute it and/or modify it under the terms of
# the Mozilla Public License version 1.1  as published by the
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt

require_relative '../data/data_set'
require_relative '../clusterers/single_linkage'
require_relative '../clusterers/cluster_tree'

module Ai4r
  module Clusterers

    # Implementation of a Hierarchical clusterer with group average
    # linkage, AKA unweighted pair group method average or UPGMA (Everitt
    # et al., 2001 ; Jain and Dubes, 1988 ; Sokal and Michener, 1958).
    # Hierarchical clusterer create one cluster per element, and then
    # progressively merge clusters, until the required number of clusters
    # is reached.
    # With average linkage, the distance between a clusters cx and
    # cluster (ci U cj) the the average distance between cx and ci, and
    # cx and cj.
    #
    #   D(cx, (ci U cj) = (D(cx, ci) + D(cx, cj)) / 2
    class AverageLinkage < SingleLinkage

      include ClusterTree

      parameters_info distance_function:
          "Custom implementation of distance function. " +
          "It must be a closure receiving two data items and return the " +
          "distance between them. By default, this algorithm uses " +
          "euclidean distance of numeric attributes to the power of 2."

      # Build a new clusterer, using data examples found in data_set.
      # Items will be clustered in "number_of_clusters" different
      # clusters.
      # @param data_set [Object]
      # @param number_of_clusters [Object]
      # @param *options [Object]
      # @return [Object]
      def build(data_set, number_of_clusters = 1, **options)
        super
      end

      # This algorithms does not allow classification of new data items
      # once it has been built. Rebuild the cluster including you data element.
      # @param _data_item [Object]
      # @return [Object]
      def eval(_data_item)
        raise NotImplementedError, 'Eval of new data is not supported by this algorithm.'
      end

      # Average linkage builds a dendrogram and cannot classify new data
      # once built.
      # @return [Object]
      def supports_eval?
        false
      end

      protected

      # return distance between cluster cx and cluster (ci U cj),
      # using average linkage
      # @param cx [Object]
      # @param ci [Object]
      # @param cj [Object]
      # @return [Object]
      def linkage_distance(cx, ci, cj)
        (read_distance_matrix(cx, ci)+
          read_distance_matrix(cx, cj))/2
      end

    end
  end
end
