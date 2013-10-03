defmodule QueryTest do
  use ExUnit.Case, async: true

  setup do
    { :ok, pid } = Postgrex.connect("localhost", "postgres", "postgres", "postgrex_test", [])
    { :ok, [pid: pid] }
  end

  teardown context do
    :ok = Postgrex.disconnect(context[:pid])
  end

  test "decode basic types", context do
    assert { :ok, [{ nil }] } = Postgrex.query(context[:pid], "SELECT NULL")
    assert { :ok, [{ true, false }] } = Postgrex.query(context[:pid], "SELECT true, false")
    assert { :ok, [{ "e" }] } = Postgrex.query(context[:pid], "SELECT 'e'::char")
    assert { :ok, [{ "ẽ" }] } = Postgrex.query(context[:pid], "SELECT 'ẽ'::char")
    assert { :ok, [{ 42 }] } = Postgrex.query(context[:pid], "SELECT 42")
    assert { :ok, [{ 42.0 }] } = Postgrex.query(context[:pid], "SELECT 42::float")
    assert { :ok, [{ "ẽric" }] } = Postgrex.query(context[:pid], "SELECT 'ẽric'")
    assert { :ok, [{ "ẽric" }] } = Postgrex.query(context[:pid], "SELECT 'ẽric'::varchar")
    assert { :ok, [{ << 1, 2, 3 >> }] } = Postgrex.query(context[:pid], "SELECT '\\001\\002\\003'::bytea")
  end

  test "decode arrays", context do
    assert { :ok, [{ [] }] } = Postgrex.query(context[:pid], "SELECT ARRAY[]::integer[]")
    assert { :ok, [{ [1] }] } = Postgrex.query(context[:pid], "SELECT ARRAY[1]")
    assert { :ok, [{ [1,2] }] } = Postgrex.query(context[:pid], "SELECT ARRAY[1,2]")
    assert { :ok, [{ [[0],[1]] }] } = Postgrex.query(context[:pid], "SELECT ARRAY[[0],[1]]")
    assert { :ok, [{ [[0]] }] } = Postgrex.query(context[:pid], "SELECT ARRAY[ARRAY[0]]")
  end

  test "decode time", context do
    assert { :ok, [{ {0,0,0} }] } = Postgrex.query(context[:pid], "SELECT time '00:00:00'")
    assert { :ok, [{ {1,2,3} }] } = Postgrex.query(context[:pid], "SELECT time '01:02:03'")
    assert { :ok, [{ {23,59,59} }] } = Postgrex.query(context[:pid], "SELECT time '23:59:59'")
    assert { :ok, [{ {4,5,6} }] } = Postgrex.query(context[:pid], "SELECT time '04:05:06 PST'")
  end

  test "decode date", context do
    assert { :ok, [{ {1,1,1} }] } = Postgrex.query(context[:pid], "SELECT date '0001-01-01'")
    assert { :ok, [{ {1,2,3} }] } = Postgrex.query(context[:pid], "SELECT date '0001-02-03'")
    assert { :ok, [{ {2013,9,23} }] } = Postgrex.query(context[:pid], "SELECT date '2013-09-23'")
  end

  test "decode timestamp", context do
    assert { :ok, [{ {{1,1,1},{0,0,0}} }] } = Postgrex.query(context[:pid], "SELECT timestamp '0001-01-01 00:00:00'")
    assert { :ok, [{ {{2013,9,23},{14,4,37}} }] } = Postgrex.query(context[:pid], "SELECT timestamp '2013-09-23 14:04:37'")
    assert { :ok, [{ {{2013,9,23},{14,4,37}} }] } = Postgrex.query(context[:pid], "SELECT timestamp '2013-09-23 14:04:37 PST'")
  end

  test "decode interval", context do
    assert { :ok, [{ {0,0,0} }] } = Postgrex.query(context[:pid], "SELECT interval '0'")
    assert { :ok, [{ {0,100,0} }] } = Postgrex.query(context[:pid], "SELECT interval '100 days'")
    assert { :ok, [{ {180000,0,0} }] } = Postgrex.query(context[:pid], "SELECT interval '50 hours'")
    assert { :ok, [{ {1,0,0} }] } = Postgrex.query(context[:pid], "SELECT interval '1 second'")
    assert { :ok, [{ {10920,40,14} }] } = Postgrex.query(context[:pid], "SELECT interval '1 year 2 months 40 days 3 hours 2 minutes'")
  end

  test "encode basic types", context do
    assert { :ok, [{ nil, nil }] } = Postgrex.query(context[:pid], "SELECT $1::text, $2::int", [nil, nil])
    assert { :ok, [{ true, false }] } = Postgrex.query(context[:pid], "SELECT $1::bool, $2::bool", [true, false])
    assert { :ok, [{ "ẽ" }] } = Postgrex.query(context[:pid], "SELECT $1::char", ["ẽ"])
    assert { :ok, [{ 42 }] } = Postgrex.query(context[:pid], "SELECT $1::int", [42])
    assert { :ok, [{ 42.0, 43.0 }] } = Postgrex.query(context[:pid], "SELECT $1::float, $2::float", [42, 43.0])
    assert { :ok, [{ "ẽric" }] } = Postgrex.query(context[:pid], "SELECT $1::varchar", ["ẽric"])
    assert { :ok, [{ << 1, 2, 3 >> }] } = Postgrex.query(context[:pid], "SELECT $1::bytea", [<< 1, 2, 3 >>])
  end

  test "encode date", context do
    assert { :ok, [{ {1,1,1} }] } = Postgrex.query(context[:pid], "SELECT $1::date", [{1,1,1}])
    assert { :ok, [{ {1,2,3} }] } = Postgrex.query(context[:pid], "SELECT $1::date", [{1,2,3}])
    assert { :ok, [{ {2013,9,23} }] } = Postgrex.query(context[:pid], "SELECT $1::date", [{2013,9,23}])
  end

  test "encode time", context do
    assert { :ok, [{ {0,0,0} }] } = Postgrex.query(context[:pid], "SELECT $1::time", [{0,0,0}])
    assert { :ok, [{ {1,2,3} }] } = Postgrex.query(context[:pid], "SELECT $1::time", [{1,2,3}])
    assert { :ok, [{ {23,59,59} }] } = Postgrex.query(context[:pid], "SELECT $1::time", [{23,59,59}])
    assert { :ok, [{ {4,5,6} }] } = Postgrex.query(context[:pid], "SELECT $1::time", [{4,5,6}])
  end

  test "encode timestamp", context do
    assert { :ok, [{ {{1,1,1},{0,0,0}} }] } =
      Postgrex.query(context[:pid], "SELECT $1::timestamp", [{{1,1,1},{0,0,0}}])
    assert { :ok, [{ {{2013,9,23},{14,4,37}} }] } =
      Postgrex.query(context[:pid], "SELECT $1::timestamp", [{{2013,9,23},{14,4,37}}])
    assert { :ok, [{ {{2013,9,23},{14,4,37}} }] } =
      Postgrex.query(context[:pid], "SELECT $1::timestamp", [{{2013,9,23},{14,4,37}}])
  end

  test "encode interval", context do
    assert { :ok, [{ {0,0,0} }] } =
      Postgrex.query(context[:pid], "SELECT $1::interval", [{0,0,0}])
    assert { :ok, [{ {0,100,0} }] } =
      Postgrex.query(context[:pid], "SELECT $1::interval", [{0,100,0}])
    assert { :ok, [{ {180000,0,0} }] } =
      Postgrex.query(context[:pid], "SELECT $1::interval", [{180000,0,0}])
    assert { :ok, [{ {1,0,0} }] } =
      Postgrex.query(context[:pid], "SELECT $1::interval", [{1,0,0}])
    assert { :ok, [{ {10920,40,14} }] } =
      Postgrex.query(context[:pid], "SELECT $1::interval", [{10920,40,14}])
  end

  test "encode arrays", context do
    assert { :ok, [{ [] }] } = Postgrex.query(context[:pid], "SELECT $1::integer[]", [[]])
    assert { :ok, [{ [1] }] } = Postgrex.query(context[:pid], "SELECT $1::integer[]", [[1]])
    assert { :ok, [{ [1,2] }] } = Postgrex.query(context[:pid], "SELECT $1::integer[]", [[1,2]])
    assert { :ok, [{ [[0],[1]] }] } = Postgrex.query(context[:pid], "SELECT $1::integer[]", [[[0],[1]]])
    assert { :ok, [{ [[0]] }] } = Postgrex.query(context[:pid], "SELECT $1::integer[]", [[[0]]])
  end
end
