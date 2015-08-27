require "pg"

module Db
  def exec(sql, &block)
    connection.exec(sql, &block)
  end

  def exec_first(sql, &block)
    exec(sql, &block).first
  end

  def unescape(string)
    string.to_s.gsub(/"/, "")
  end

  def connection
    @connection ||= PG.connect(dbname: "rank_cross_test")
  end

  def drop_tables
    exec "DROP TABLE IF EXISTS products;"
    exec "DROP TABLE IF EXISTS categories;"
  end

  def create_tables
    exec "CREATE TABLE IF NOT EXISTS products (id serial CONSTRAINT firstkey PRIMARY KEY, title text);"
    exec "CREATE TABLE IF NOT EXISTS categories (category_id integer NOT NULL, product_id integer NOT NULL, position integer NOT NULL);"
    exec "CREATE UNIQUE INDEX index_categories_on_category_id_and_product_id ON categories (category_id, product_id);"
  end

  def load_sql
    sql = File.read("lib/functions.sql")
    exec(sql)
  end
end
