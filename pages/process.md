## Il processo

- Job su Oban ogni 5 minuti che lancia la funzione definita su postgres 

  ```sql 
  select populate_missing_field(max_cdr_to_process)
  ```
<v-click>

- Il job ha un timeout di un'ora

</v-click>
<v-click>

- I job non finiscono mai, e va in timeout prima di aver finito

</v-click>