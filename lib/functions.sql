-- "Constants" --

CREATE OR REPLACE FUNCTION ranked_step()
  RETURNS integer AS
$$SELECT 10000::integer$$ LANGUAGE sql IMMUTABLE;

-- Helper functions --

CREATE OR REPLACE FUNCTION ranked_get_last_position_in_category(cat_id integer, OUT last_position integer) RETURNS integer AS $$
BEGIN
  SELECT MAX(position) INTO last_position FROM categories WHERE category_id = cat_id;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ranked_get_rank_in_category(cat_id integer, prod_id integer, OUT rank integer) RETURNS integer AS $$
DECLARE
  product_position integer;
BEGIN
  SELECT position INTO product_position FROM categories WHERE category_id = cat_id AND product_id = prod_id;

  SELECT COUNT(
      CASE WHEN position <= product_position THEN 1 ELSE NULL END
    ) INTO rank
    FROM categories
    WHERE category_id = cat_id;
  IF rank = 0 THEN
    rank := NULL;
  END IF;
END
$$ LANGUAGE plpgsql;

-- Return position value for the product with specific rank in given categrory or NULL if such rank wasn't found
CREATE OR REPLACE FUNCTION ranked_get_position_for_rank_in_category(cat_id integer, rank integer, OUT pos integer) AS $$
BEGIN
  IF rank <= 0 THEN
    pos := NULL;
    RETURN;
  END IF;
  SELECT position INTO pos
    FROM categories
    WHERE category_id = cat_id
    ORDER BY position
    OFFSET rank - 1
    LIMIT 1;
END
$$ LANGUAGE plpgsql;

-- Puts product to the specified rank in category
CREATE OR REPLACE FUNCTION ranked_set_product_rank_in_category(cat_id integer, prod_id integer, rank integer) RETURNS void AS $$
DECLARE
  pos integer;
  upper integer;
  lower integer;
BEGIN
  IF rank <= 0 THEN
    RAISE 'Rank should be equal to or greater than 1';
  END IF;
  -- Do nothing if product already has required rank
  IF ranked_get_rank_in_category(cat_id, prod_id) = rank THEN
    RETURN;
  END IF;
  SELECT ranked_get_position_for_rank_in_category(cat_id, rank - 1) INTO upper;
  SELECT ranked_get_position_for_rank_in_category(cat_id, rank) INTO lower;
  IF upper IS NULL AND lower IS NULL THEN
    SELECT ranked_get_last_position_in_category(cat_id) INTO pos;
    IF pos IS NOT NULL THEN
      pos := pos + ranked_step();
    ELSE
      pos := 0;
    END IF;
  ELSIF upper IS NULL THEN
    pos := 0;
  ELSIF lower IS NULL THEN
    pos := upper + ranked_step();
  ELSE
    pos := upper + ceil((lower - upper) / 2);
  END IF;

  UPDATE categories SET position = pos WHERE category_id = cat_id AND product_id = prod_id;
END
$$ LANGUAGE plpgsql;

-- Triggers --

-- Checks that product has correct positions for all categories. Also deletes positions for deleted categories.
CREATE OR REPLACE FUNCTION ranked_set_product_position() RETURNS trigger AS $$
DECLARE
  pos integer;
  last_position integer;
BEGIN
  IF NEW.position IS NOT NULL THEN
    RETURN NEW;
  END IF;

  SELECT ranked_get_last_position_in_category(NEW.category_id) INTO last_position;
  IF last_position IS NOT NULL THEN
    pos := last_position + ranked_step();
  ELSE
    pos := 0;
  END IF;
  NEW.position := pos;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ranked_set_product_position BEFORE INSERT OR UPDATE ON categories FOR EACH ROW EXECUTE PROCEDURE ranked_set_product_position();

-- Makes sure that every position is unique within category by moving duplicated products down
CREATE OR REPLACE FUNCTION ranked_check_product_positions_uniqueness() RETURNS trigger AS $$
DECLARE
  existing_product integer;
BEGIN
  SELECT 1 INTO existing_product FROM categories WHERE product_id <> NEW.product_id AND category_id = NEW.category_id AND position = NEW.position;
  IF existing_product IS NULL THEN
    RETURN NULL;
  END IF;

  UPDATE categories SET position = (position + ranked_step()) WHERE product_id <> NEW.product_id AND category_id = NEW.category_id AND position >= NEW.position;
  RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ranked_check_product_positions_uniqueness AFTER INSERT OR UPDATE ON categories FOR EACH ROW EXECUTE PROCEDURE ranked_check_product_positions_uniqueness();
