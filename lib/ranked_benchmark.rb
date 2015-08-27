$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "benchmark"
require "db"

class RankedBenchmark
  include Db

  N_PRODUCTS = 1000
  N_CATEGORIES = 10

  def run
    drop_tables
    create_tables
    load_sql

    Benchmark.bm(20) do |x|
      x.report("Create products") do
        (1..N_CATEGORIES).each do |cat|
          (1..N_PRODUCTS).each do |prod|
            id = exec("INSERT INTO products (title) VALUES ('Product #{cat} #{prod}') RETURNING id;").first["id"]
            exec("INSERT INTO categories (category_id, product_id) VALUES (#{cat}, #{id});")
          end
        end
      end

      x.report("Change rank") do
        (1..N_CATEGORIES).each do |cat|
          last_product_id = exec_first("SELECT product_id FROM categories WHERE category_id = #{cat} ORDER BY position DESC LIMIT 1;")["product_id"]
          exec("SELECT ranked_set_product_rank_in_category(#{cat}, #{last_product_id}, #{N_PRODUCTS / 2});")
        end
      end

      x.report("Select all products") do
        (1..N_CATEGORIES).each do |cat|
          exec("SELECT products.id, products.title, ranked_get_rank_in_category(#{cat}, products.id) as rank FROM products LEFT JOIN categories ON products.id = categories.product_id WHERE categories.category_id = #{cat} ORDER BY rank;")
        end
      end
    end
  end
end
