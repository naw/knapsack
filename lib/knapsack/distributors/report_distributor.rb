module Knapsack
  module Distributors
    class ReportDistributor < BaseDistributor
      def sorted_report
        @sorted_report ||= report.sort_by { |test_path, time| time }.reverse
      end

      def sorted_report_with_existing_tests
        @sorted_report_with_existing_tests ||= sorted_report.select { |test_path, time| all_tests.include?(test_path) }
      end

      def total_time_execution
        @total_time_execution ||= sorted_report_with_existing_tests.map(&:last).reduce(0, :+).to_f
      end

      def node_time_execution
        @node_time_execution ||= total_time_execution / ci_node_total
      end

      private

      def post_assign_test_files_to_node
        assign_test_files
        sort_assigned_test_files
      end

      def sort_assigned_test_files
        ci_node_total.times do |index|
          # sort by first key (file name)
          # reverse it and then sort by second key (time) in reverse order
          node_tests[index][:test_files_with_time].sort!.reverse!.sort! do |x, y|
            y[1] <=> x[1]
          end
        end
      end

      def post_tests_for_node(node_index)
        node_test = node_tests[node_index]
        return unless node_test
        node_test[:test_files_with_time].map(&:first)
      end

      def default_node_tests
        @node_tests = []
        ci_node_total.times do |index|
          @node_tests << {
            node_index: index,
            time: 0,
            test_files_with_time: []
          }
        end
      end

      def assign_test_files
        sorted_report_with_existing_tests.each do |test_file_with_time|
          index = node_with_min_time
          time = test_file_with_time[1]
          node_tests[index][:time] += time
          node_tests[index][:test_files_with_time] << test_file_with_time
        end
      end

      def node_with_min_time
        node_test = node_tests.min { |a,b| a[:time] <=> b[:time] }
        node_test[:node_index]
      end
    end
  end
end
