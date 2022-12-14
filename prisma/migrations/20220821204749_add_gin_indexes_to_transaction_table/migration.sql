CREATE EXTENSION pg_trgm;
CREATE EXTENSION btree_gin;

CREATE INDEX "Transaction_fulltext_search_idx" ON "Transaction" USING GIN (
    (
        setweight(to_tsvector('english', coalesce("reference", '')), 'A') ||
        setweight(to_tsvector('english', coalesce("currency", '')), 'B')
    )
);