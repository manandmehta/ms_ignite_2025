CREATE EXTENSION IF NOT EXISTS azure_ai;

SELECT azure_ai.set_setting('azure_openai.subscription_key', 'eb486796cbb3408b89be1cb38cf7f4f4');
SELECT azure_ai.get_setting('azure_openai.endpoint');

SELECT id, name, opinion
FROM cases
WHERE opinion ILIKE '%Water leaking into the apartment from the floor above';

CREATE EXTENSION IF NOT EXISTS vector;

ALTER TABLE cases ADD COLUMN opinions_vector vector(1536);

UPDATE cases
SET opinions_vector = azure_openai.create_embeddings('text-embedding-3-small',  name || LEFT(opinion, 8000), max_attempts => 5, retry_delay_ms => 500)::vector
WHERE opinions_vector IS NULL;


CREATE EXTENSION IF NOT EXISTS pg_diskann;

-- as you scale your data to millions of rows, DiskANN makes vector search more effcient.
CREATE INDEX cases_cosine_diskann ON cases USING diskann(opinions_vector vector_cosine_ops);

SELECT opinions_vector FROM cases LIMIT 1;


-- Doing schemantic search 
/*
To intuitively understand semantic search, observe that the opinion mentioned doesn't actually contain the terms "Water leaking into the apartment from the floor above." However it does highlight a document with a section that says nonsuit and dismissal, in 
an action brought by a tenant to recover damages for injuries to her goods, caused by leakage of water from an upper story"
*/
SELECT 
    id, name, opinion
FROM 
    cases
ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector 
LIMIT 1;