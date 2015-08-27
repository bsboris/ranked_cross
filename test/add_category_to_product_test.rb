require "test_helper"

class AddCategoryToProductTest < MiniTest::Test
  def test_sets_position_when_it_have_category
    exec("INSERT INTO categories (category_id, product_id) VALUES (1, 1);")

    assert_equal "0", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
  end

  def test_sets_position_with_step_10000
    exec("INSERT INTO categories (category_id, product_id) VALUES (1, 1);")
    exec("INSERT INTO categories (category_id, product_id) VALUES (1, 2);")

    assert_equal "10000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 2;")["position"]
  end

  def test_allows_manually_set_position
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 1, 10000);")

    assert_equal "10000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
  end

  def test_moves_all_products_down_on_duplicate
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 1, 10000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 2, 20000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 3, 30000);")

    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 4, 10000);")

    assert_equal "10000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 4;")["position"]
    assert_equal "20000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
    assert_equal "30000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 2;")["position"]
    assert_equal "40000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 3;")["position"]
  end

  def test_positions_are_unique
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 1, 10000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 2, 10000);")


    assert_equal "10000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 2;")["position"]
    assert_equal "20000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
  end

  def test_positions_are_unique_on_update
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 1, 10000);")
    exec("INSERT INTO categories (category_id, product_id, position) VALUES (1, 2, 20000);")
    exec("UPDATE categories SET position = 10000 WHERE product_id = 2;")

    assert_equal "10000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 2;")["position"]
    assert_equal "20000", exec_first("SELECT position FROM categories WHERE category_id = 1 AND product_id = 1;")["position"]
  end
end
