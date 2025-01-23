
## TIL 1

Postgres garantisce l'integrita' per i __single statement__ di default. La struttura:

```sql 
BEGIN
...
update 1;
...
update 2;
...
COMMIT
```

serve per garantire l'integrita' di business in caso di __multiple statement__, come nel caso di piu' update in contemporanea. 
