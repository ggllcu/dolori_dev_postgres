
## Soluzione 3: condizione ridondante

E se la facessi cosi' (ma non so perche')?

````md magic-move {lines: true}
```sql
WITH c AS
  (SELECT id,
          unique_identifier,
          datetime
   FROM main_table
   WHERE missing_field IS NULL
   LIMIT max_cdr_to_process)
UPDATE main_table AS t
SET missing_field = coalesce(
                           (SELECT missing_field
                            FROM helper_table AS u
                            WHERE u.unique_identifier = c.unique_identifier
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
FROM c
WHERE c.id = t.id;
```

```sql{17-18}
WITH c AS
  (SELECT id,
          unique_identifier,
          datetime
   FROM main_table
   WHERE missing_field IS NULL
   LIMIT max_cdr_to_process)
UPDATE main_table AS t
SET missing_field = coalesce(
                           (SELECT missing_field
                            FROM helper_table AS u
                            WHERE u.unique_identifier = c.unique_identifier
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
FROM c
WHERE c.id = t.id
  AND missing_field IS NULL;
```
````

---

Impostiamo il campo come null su tutte le righe:

```sql    
UPDATE main_table SET missing_field = null;
-- Time: 5160102.544 ms (01:26:00.103)
```

---

Torniamo alla funzione `populate_missing_field`. 

````md magic-move
```sql    
SELECT cdr.populate_missing_field(10);
-- Time: 6123.360 ms (00:06.123)
```

```sql    
SELECT cdr.populate_missing_field(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_missing_field(20);
-- Time: 6392.647 ms (00:06.393)
```

```sql    
SELECT cdr.populate_missing_field(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_missing_field(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_missing_field(50);
-- Time: 5869.910 ms (00:05.870)
```

```sql    
SELECT cdr.populate_missing_field(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_missing_field(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_missing_field(50);
-- Time: 5869.910 ms (00:05.870)

SELECT cdr.populate_missing_field(100);
-- Time: 5929.555 ms (00:05.930)
```

```sql    
SELECT cdr.populate_missing_field(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_missing_field(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_missing_field(50);
-- Time: 5869.910 ms (00:05.870)

SELECT cdr.populate_missing_field(100);
-- Time: 5929.555 ms (00:05.930)

SELECT cdr.populate_missing_field(1000);
-- Time: 7175.841 ms (00:07.176)
```

```sql    
SELECT cdr.populate_missing_field(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_missing_field(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_missing_field(50);
-- Time: 5869.910 ms (00:05.870)

SELECT cdr.populate_missing_field(100);
-- Time: 5929.555 ms (00:05.930)

SELECT cdr.populate_missing_field(1000);
-- Time: 7175.841 ms (00:07.176)

SELECT cdr.populate_missing_field(10000);
-- Time: 242200.066 ms (04:02.200)
```
````

---
layout: image
image: /img/populate_missing_field_double_condition.svg
backgroundSize: contain
---
