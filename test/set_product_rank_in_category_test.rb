require "test_helper"

class SetProductRankInCategoryTest < MiniTest::Test
  def setup
    super

    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 1, 0);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 2, 10000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 3, 20000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 4, 30000);")
  end

  def test_sets_product_between_products
    exec("SELECT ranked_set_product_rank_in_category(1, 4, 3);")

    assert_equal "15000",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 4;")["position"]
    assert_equal "10000",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 2;")["position"]
    assert_equal "20000",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 3;")["position"]
  end

  def test_sets_product_on_top
    exec("SELECT ranked_set_product_rank_in_category(1, 4, 1);")

    assert_equal "0",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 4;")["position"]
    assert_equal "10000",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
    assert_equal "20000",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 2;")["position"]
  end

  def test_sets_product_to_bottom
    exec("SELECT ranked_set_product_rank_in_category(1, 1, 5);")

    assert_equal "40000",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
  end

  def test_sets_product_to_very_bottom
    exec("SELECT ranked_set_product_rank_in_category(1, 1, 999);")

    assert_equal "40000",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
  end

  def test_doesnt_change_position_if_already_ranked
    exec("SELECT ranked_set_product_rank_in_category(1, 1, 1);")

    assert_equal "0",
                 exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
  end
end
