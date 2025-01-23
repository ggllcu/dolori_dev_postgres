
## TIL 2

Postgres utilizza una funzione __autovacuum__ per pulire il db dopo alcune operazioni. Questa funzione, nel mio caso, impiegava fino ad un'ora circa. Non me ne ero accorto, e inizialmente questa cosa mi sballava parecchio i test. 

Se fate test intensivi sul db, controllate con un __htop__ o direttamente da __psql__ che non ci siano operazioni di manutenzione di postgres in backgroup perche' vi falserebbero i risultati.

```sql
SELECT * FROM pg_stat_activity WHERE state = 'active';

``` 
