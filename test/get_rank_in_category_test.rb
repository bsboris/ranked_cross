require "test_helper"

class GetRankInCategoryTest < Minitest::Test
  def setup
    super

    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 1, 0);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 2, 10000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 3, 20000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 4, 30000);")
  end

  def test_returns_ranks_in_category
    assert_equal [1, 2, 3, 4],
                 exec("SELECT ranked_get_rank_in_category(1, product_id) as rank FROM categories;").map { |row| row["rank"].to_i }
  end

  def test_returns_rank_in_category
    rank =

    assert_equal "3",
                 exec_first("SELECT ranked_get_rank_in_category(1, product_id) as rank FROM categories WHERE product_id = 3;")["rank"]
  end

  def test_returns_nil_for_missing_category
    assert_equal nil,
                 exec_first("SELECT ranked_get_rank_in_category(999, product_id) as rank FROM categories;")["rank"]
  end
end
