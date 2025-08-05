defmodule MySciNet.JobQueryTest do
  use ExUnit.Case, async: true

  alias MySciNet.JobQuery

  describe ".parse/1" do
    test "parses empty string as []" do
      assert JobQuery.parse(" ") == {:ok, []}
    end

    test "parses 'cluster:trillium nodes:4' as [{:is_eq, :cluster, :trillium},{:is_eq, :nodes, 4}]" do
      assert JobQuery.parse("cluster:trillium nodes:4") == {:ok, [{:is_eq, :cluster, :trillium}, {:is_eq, :nodes, 4}]}
    end

    test "parses 'cluster:trillium' as [{:is_eq, :cluster, :trillium}]" do
      assert JobQuery.parse("cluster:trillium") == {:ok, [{:is_eq, :cluster, :trillium}]}
    end

    test "parses 'nodes:4' as [{:is_eq, :nodes, 4}]" do
      assert JobQuery.parse("nodes:4") == {:ok, [{:is_eq, :nodes, 4}]}
    end

    test "parses 'nodes<4' as [{:is_lt, :nodes, 4}]" do
      assert JobQuery.parse("nodes<4") == {:ok, [{:is_lt, :nodes, 4}]}
    end

    test "parses 'nodes<=4' as [{:is_le, :nodes, 4}]" do
      assert JobQuery.parse("nodes<=4") == {:ok, [{:is_le, :nodes, 4}]}
    end

    test "parses 'nodes>4' as [{:is_gt, :nodes, 4}]" do
      assert JobQuery.parse("nodes>4") == {:ok, [{:is_gt, :nodes, 4}]}
    end

    test "parses 'nodes>=4' as [{:is_ge, :nodes, 4}]" do
      assert JobQuery.parse("nodes>=4") == {:ok, [{:is_ge, :nodes, 4}]}
    end
  end
end
