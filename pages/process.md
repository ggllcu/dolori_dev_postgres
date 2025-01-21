### Il processo

- Job su Oban ogni 5 minuti che lancia una funzione definita su postgres 

  ```sql 
  select populate_missing_field(max_rows)
  ```
<v-click>

- Il job ha un timeout di un'ora

</v-click>
<v-click>

- I job non finiscono mai, e va in timeout prima di aver finito

</v-click>
<v-click>

- Due settimane di tempo per sbloccare il database

</v-click>