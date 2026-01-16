CREATE TABLE test (
  id      BIGSERIAL PRIMARY KEY,
  code    CHAR(10)    NOT NULL,
  name    VARCHAR(50) NOT NULL,
  qty     INT         NOT NULL,
  flag    CHAR(1)     NOT NULL,
  payload TEXT
);

INSERT INTO test (code, name, qty, flag, payload)
SELECT
  lpad(gs::text, 10, '0')::char(10) AS code,
  'item_' || gs AS name,
  (random() * 1000)::int AS qty,
  (ARRAY['A','B','C','D'])[1 + floor(random() * 4)]::char(1) AS flag,
  md5(random()::text) AS payload
FROM generate_series(1, 10000) AS gs;

CREATE TABLE products (
  id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at  TIMESTAMP NOT NULL,
  active      BOOLEAN   NOT NULL,
  sort        INT       NOT NULL,
  price       NUMERIC(12,2) NOT NULL,
  code        CHAR(10)  NOT NULL,
  name        CHAR(20)  NOT NULL,
  description CHAR(60)  NOT NULL
);

INSERT INTO products (created_at, active, sort, price, code, name, description)
SELECT
  now() - (random() * interval '365 days') AS created_at,
  (random() < 0.7) AS active,
  gs AS sort,
  round((random() * 10000)::numeric, 2) AS price,
  lpad(gs::text, 10, '0')::char(10) AS code,
  rpad(('name_' || gs)::text, 20, ' ')::char(20) AS name,
  rpad(('desc_' || md5(gs::text))::text, 60, ' ')::char(60) AS description
FROM generate_series(1, 10000) AS gs;

-----------------------------------------------------------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, code, name, price
FROM products
WHERE active = true
ORDER BY sort
LIMIT 100;

"Limit  (cost=560.34..560.59 rows=100 width=46) (actual time=2.538..2.548 rows=100 loops=1)"
"  Buffers: shared hit=193"
"  ->  Sort  (cost=560.34..577.83 rows=6995 width=46) (actual time=2.537..2.541 rows=100 loops=1)"
"        Sort Key: sort"
"        Sort Method: top-N heapsort  Memory: 32kB"
"        Buffers: shared hit=193"
"        ->  Seq Scan on products  (cost=0.00..293.00 rows=6995 width=46) (actual time=0.008..1.400 rows=6995 loops=1)"
"              Filter: active"
"              Rows Removed by Filter: 3005"
"              Buffers: shared hit=193"
"Planning Time: 0.057 ms"
"Execution Time: 2.569 ms"

"B-tree"
CREATE INDEX idx_products_active_sort
ON products (sort)
INCLUDE (id, code, name, price)
WHERE active = true;

"Limit  (cost=0.28..5.21 rows=100 width=46) (actual time=0.103..0.122 rows=100 loops=1)"
"  Buffers: shared hit=1 read=2"
"  ->  Index Only Scan using idx_products_active_sort on products  (cost=0.28..345.21 rows=6995 width=46) (actual time=0.102..0.114 rows=100 loops=1)"
"        Heap Fetches: 0"
"        Buffers: shared hit=1 read=2"
"Planning Time: 0.084 ms"
"Execution Time: 0.141 ms"

-----------------------------------------------------------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM products
WHERE code = '0000000004';

"Seq Scan on products  (cost=0.00..318.00 rows=1 width=116) (actual time=0.007..3.149 rows=1 loops=1)"
"  Filter: (code = '0000000004'::bpchar)"
"  Rows Removed by Filter: 9999"
"  Buffers: shared hit=193"
"Planning:"
"  Buffers: shared hit=6"
"Planning Time: 0.066 ms"
"Execution Time: 3.160 ms"

"HASH"
CREATE INDEX idx_products_code_hash
ON products USING HASH (code);

"Index Scan using idx_products_code_hash on products  (cost=0.00..8.02 rows=1 width=116) (actual time=0.012..0.012 rows=1 loops=1)"
"  Index Cond: (code = '0000000004'::bpchar)"
"  Buffers: shared hit=3"
"Planning:"
"  Buffers: shared hit=16"
"Planning Time: 0.097 ms"
"Execution Time: 0.023 ms"

-----------------------------------------------------------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM products
WHERE sort BETWEEN 9000 AND 9050;

"Seq Scan on products  (cost=0.00..343.00 rows=51 width=116) (actual time=0.813..0.903 rows=51 loops=1)"
"  Filter: ((sort >= 9000) AND (sort <= 9050))"
"  Rows Removed by Filter: 9949"
"  Buffers: shared hit=193"
"Planning:"
"  Buffers: shared hit=6 dirtied=1"
"Planning Time: 0.076 ms"
"Execution Time: 0.915 ms"

CREATE INDEX idx_products_sort_brin
ON products USING BRIN (sort);

"Bitmap Heap Scan on products  (cost=12.04..280.04 rows=51 width=116) (actual time=0.279..0.387 rows=51 loops=1)"
"  Recheck Cond: ((sort >= 9000) AND (sort <= 9050))"
"  Rows Removed by Index Recheck: 3293"
"  Heap Blocks: lossy=65"
"  Buffers: shared hit=67"
"  ->  Bitmap Index Scan on idx_products_sort_brin  (cost=0.00..12.03 rows=5000 width=0) (actual time=0.009..0.009 rows=650 loops=1)"
"        Index Cond: ((sort >= 9000) AND (sort <= 9050))"
"        Buffers: shared hit=2"
"Planning:"
"  Buffers: shared hit=17"
"Planning Time: 0.112 ms"
"Execution Time: 0.405 ms"

-----------------------------------------------------------------------------------------------------------------------------

CREATE TABLE items_arr (
  id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  active      BOOLEAN NOT NULL,
  sort        INT NOT NULL,
  tags        TEXT[] NOT NULL,
  nums        INT[]  NOT NULL
);

INSERT INTO items_arr (active, sort, tags, nums)
SELECT
  (random() < 0.7) AS active,
  gs               AS sort,
  ARRAY[
    't' || lpad((((gs * 17) % 2000) + 1)::text, 4, '0'),
    't' || lpad((((gs * 31) % 2000) + 1)::text, 4, '0'),
    't' || lpad((((gs * 47) % 2000) + 1)::text, 4, '0'),
    't' || lpad((((gs * 73) % 2000) + 1)::text, 4, '0'),
    't' || lpad((((gs * 91) % 2000) + 1)::text, 4, '0')
  ] AS tags,
  ARRAY[
    ((gs * 3) % 1000),
    ((gs * 7) % 1000),
    ((gs * 11) % 1000)
  ] AS nums
FROM generate_series(1, 10000) gs;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, tags
FROM items_arr
WHERE active = true
  AND tags @> ARRAY['t0123'];

"Seq Scan on items_arr  (cost=0.00..386.00 rows=39 width=36) (actual time=0.065..2.467 rows=16 loops=1)"
"  Filter: (active AND (tags @> '{t0123}'::text[]))"
"  Rows Removed by Filter: 9984"
"  Buffers: shared hit=193"
"Planning:"
"  Buffers: shared hit=3"
"Planning Time: 0.060 ms"
"Execution Time: 2.476 ms"

CREATE INDEX idx_items_arr_tags_gin
ON items_arr USING GIN (tags);

"Bitmap Heap Scan on items_arr  (cost=12.87..52.05 rows=9 width=85) (actual time=0.017..0.039 rows=16 loops=1)"
"  Recheck Cond: (tags @> '{t0123}'::text[])"
"  Filter: active"
"  Rows Removed by Filter: 9"
"  Heap Blocks: exact=20"
"  Buffers: shared hit=23"
"  ->  Bitmap Index Scan on idx_items_arr_tags_gin  (cost=0.00..12.87 rows=12 width=0) (actual time=0.011..0.011 rows=25 loops=1)"
"        Index Cond: (tags @> '{t0123}'::text[])"
"        Buffers: shared hit=3"
"Planning:"
"  Buffers: shared hit=44"
"Planning Time: 0.205 ms"
"Execution Time: 0.051 ms"

-----------------------------------------------------------------------------------------------------------------------------

CREATE TABLE api_responses_json (
  id         BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  endpoint   TEXT NOT NULL,
  payload    JSONB NOT NULL
);

INSERT INTO api_responses_json (created_at, endpoint, payload)
SELECT
  now() - (gs * interval '1 minute'),
  '/v1/products',
  CASE
    WHEN random() < 0.10 THEN
      jsonb_build_object('error', 'timeout', 'status', 504, 'req_id', md5(gs::text))
    ELSE
      jsonb_build_object('status', 'ok', 'data', jsonb_build_object('id', gs, 'v', random()))
  END
FROM generate_series(1, 10000) gs;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM api_responses_json
WHERE payload::text LIKE '%"error"%';

"Seq Scan on api_responses_json  (cost=0.00..404.69 rows=1 width=80) (actual time=0.018..6.906 rows=1000 loops=1)"
"  Filter: ((payload)::text ~~ '%""error""%'::text)"
"  Rows Removed by Filter: 9000"
"  Buffers: shared hit=175"
"Planning:"
"  Buffers: shared hit=5"
"Planning Time: 0.064 ms"
"Execution Time: 6.949 ms"

CREATE INDEX api_responses_payload_gist_trgm
ON api_responses_json
USING GIST ((payload::text) gist_trgm_ops);

"Index Scan using api_responses_payload_gist_trgm on api_responses_json  (cost=0.28..8.29 rows=1 width=112) (actual time=0.061..1.610 rows=1000 loops=1)"
"  Index Cond: ((payload)::text ~~ '%""error""%'::text)"
"  Buffers: shared hit=1152"
"Planning:"
"  Buffers: shared hit=43 dirtied=1"
"Planning Time: 0.186 ms"
"Execution Time: 1.653 ms"

-----------------------------------------------------------------------------------------------------------------------------


docker exec -t <pg_container> pg_dump -U <user> -d <db> > db.sql
cat db.sql | docker exec -i <pg_container> psql -U app -d app




CREATE EXTENSION IF NOT EXISTS hstore;

CREATE INDEX api_responses_payload_gist
ON api_responses
USING GIST ((payload::hstore));

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, code, name, price
FROM products
WHERE active = true
ORDER BY price DESC
LIMIT 100;

"Limit  (cost=560.34..560.59 rows=100 width=42) (actual time=2.685..2.695 rows=100 loops=1)"
"  Buffers: shared hit=193"
"  ->  Sort  (cost=560.34..577.83 rows=6995 width=42) (actual time=2.684..2.688 rows=100 loops=1)"
"        Sort Key: price DESC"
"        Sort Method: top-N heapsort  Memory: 36kB"
"        Buffers: shared hit=193"
"        ->  Seq Scan on products  (cost=0.00..293.00 rows=6995 width=42) (actual time=0.010..1.326 rows=6995 loops=1)"
"              Filter: active"
"              Rows Removed by Filter: 3005"
"              Buffers: shared hit=193"
"Planning Time: 0.065 ms"
"Execution Time: 2.712 ms"









EXPLAIN (ANALYZE, BUFFERS)
SELECT id, code, name, price
FROM products
WHERE active = true AND id IN (1,5,7,8,10,34)
ORDER BY sort
LIMIT 100;

"Limit  (cost=29.86..29.87 rows=4 width=46) (actual time=0.028..0.029 rows=3 loops=1)"
"  Buffers: shared hit=13"
"  ->  Sort  (cost=29.86..29.87 rows=4 width=46) (actual time=0.027..0.028 rows=3 loops=1)"
"        Sort Key: sort"
"        Sort Method: quicksort  Memory: 25kB"
"        Buffers: shared hit=13"
"        ->  Index Scan using products_pkey on products  (cost=0.29..29.82 rows=4 width=46) (actual time=0.016..0.022 rows=3 loops=1)"
"              Index Cond: (id = ANY ('{1,5,7,8,10,34}'::integer[]))"
"              Filter: active"
"              Rows Removed by Filter: 3"
"              Buffers: shared hit=13"
"Planning Time: 0.111 ms"
"Execution Time: 0.043 ms"














EXPLAIN (ANALYZE, BUFFERS)
SELECT id, code, name, price
FROM products
WHERE active = true AND name::text LIKE 'name_9999%'
LIMIT 100;

"Limit  (cost=0.00..343.00 rows=1 width=42) (actual time=2.459..2.460 rows=0 loops=1)"
"  Buffers: shared hit=193"
"  ->  Seq Scan on products  (cost=0.00..343.00 rows=1 width=42) (actual time=2.458..2.458 rows=0 loops=1)"
"        Filter: (active AND ((name)::text ~~ 'name_9999%'::text))"
"        Rows Removed by Filter: 10000"
"        Buffers: shared hit=193"
"Planning:"
"  Buffers: shared hit=6"
"Planning Time: 0.092 ms"
"Execution Time: 2.470 ms"

"GIN"
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_products_name_active
ON products USING GIN ((name::text) gin_trgm_ops)
WHERE active = true;

"Limit  (cost=47.54..51.56 rows=1 width=42) (actual time=0.145..0.145 rows=0 loops=1)"
"  Buffers: shared hit=23"
"  ->  Bitmap Heap Scan on products  (cost=47.54..51.56 rows=1 width=42) (actual time=0.144..0.144 rows=0 loops=1)"
"        Recheck Cond: (((name)::text ~~ 'name_9999%'::text) AND active)"
"        Rows Removed by Index Recheck: 16"
"        Heap Blocks: exact=8"
"        Buffers: shared hit=23"
"        ->  Bitmap Index Scan on idx_products_name_active  (cost=0.00..47.54 rows=1 width=0) (actual time=0.124..0.124 rows=16 loops=1)"
"              Index Cond: ((name)::text ~~ 'name_9999%'::text)"
"              Buffers: shared hit=15"
"Planning:"
"  Buffers: shared hit=17"
"Planning Time: 0.143 ms"
"Execution Time: 0.160 ms"













EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM products
WHERE active = true AND created_at > now() - interval '7 days'
LIMIT 100;

"Limit  (cost=0.00..259.15 rows=100 width=116) (actual time=0.017..1.516 rows=100 loops=1)"
"  Buffers: shared hit=165"
"  ->  Seq Scan on products  (cost=0.00..368.00 rows=142 width=116) (actual time=0.016..1.510 rows=100 loops=1)"
"        Filter: (active AND (created_at > (now() - '7 days'::interval)))"
"        Rows Removed by Filter: 8441"
"        Buffers: shared hit=165"
"Planning:"
"  Buffers: shared hit=3"
"Planning Time: 0.072 ms"
"Execution Time: 1.529 ms"


DROP INDEX IF EXISTS idx_products_id_brin;



EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM products
WHERE active = true
  AND id BETWEEN 9000 AND 10000
LIMIT 100;




CREATE INDEX idx_products_created_at
ON products USING BRIN (created_at);

"Limit  (cost=0.00..260.99 rows=100 width=116) (actual time=0.017..1.544 rows=100 loops=1)"
"  Buffers: shared hit=165"
"  ->  Seq Scan on products  (cost=0.00..368.00 rows=141 width=116) (actual time=0.016..1.537 rows=100 loops=1)"
"        Filter: (active AND (created_at > (now() - '7 days'::interval)))"
"        Rows Removed by Filter: 8441"
"        Buffers: shared hit=165"
"Planning:"
"  Buffers: shared hit=25"
"Planning Time: 0.162 ms"
"Execution Time: 1.556 ms"