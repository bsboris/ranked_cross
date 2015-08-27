$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"

require "db"

class MiniTest::Test
  include Db

  def setup
    create_tables
    load_sql
  end

  def teardown
    drop_tables
  end
end
