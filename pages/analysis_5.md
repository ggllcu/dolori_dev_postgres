
<v-clicks>

1. Perche' parte JIT in funzione del parametro?
2. Perche' parte piu' tardi con la seconda (ridondante) condizione sui where?
</v-clicks>

<v-click>

JIT viene eseguito quando il costo di una query supera un certo parametro. 
</v-click>

<v-click>

```sql
SHOW jit_above_cost;
-- 100000
```
</v-click>

---

## Analisi delle funzioni

### Funzione originale

```sql
-- 10
Update on timeseries t  (cost=1.02..17703.43 rows=1850 width=477) (actual time=16.923..20.623 rows=0 loops=1)
...
Hash Join  (cost=1.02..95.30 rows=10 width=478) (actual time=0.007..0.026 rows=0 loops=1)
         Hash Cond: (t_5.id = c_4.id)
```

```sql
-- 100
Update on timeseries t  (cost=8.93..156134.29 rows=18500 width=477) (actual time=174753.610..174764.536 rows=0 loops=1)
...
Hash Join  (cost=8.93..839.40 rows=100 width=478) (actual time=0.012..0.100 rows=0 loops=1)
         Hash Cond: (t_2.id = c_1.id)
```

<v-click>

Andando a vedere dove ci sono le differenze di costo, vediamo che sono in corrispondenza delle `Hash Join`
</v-click>

<v-click>

L'hash join viene eseguito 184 volte in entrambe le query. La differenza di costo totale e' quindi 184 * (849.40 - 95.30) = __138.754,4__, che e' esattamente la differenza di costo tra le due query.
</v-click>

---

### Nuova funzione

<br>

#### Total cost

<br>

```sql
-- 10
Update on timeseries t  (cost=0.29..3609.03 rows=194 width=466) (actual time=23.394..28.693 rows=0 loops=1)

-- 100
Update on timeseries t  (cost=9.66..6422.23 rows=284 width=395) (actual time=233.401..238.015 rows=0 loops=1)

-- 1000
Update on timeseries t  (cost=9.66..40690.33 rows=1920 width=356) (actual time=1282.703..1289.448 rows=0 loops=1)

-- 10000
Update on timeseries t  (cost=9.66..390264.94 rows=19200 width=356) (actual time=189298.447..189305.867 rows=0 loops=1)
```

---
layout: image
image: /img/total_cost.svg
backgroundSize: contain
---

---

#### Hash join

```sql{all|2,7,12,17|all}
-- 10
Nested Loop  
  (cost=0.29..18.70 rows=1 width=478) (actual time=0.037..0.070 rows=0 loops=1)
         Join Filter: (t_1.id = c.id)

-- 100
Hash Join
  (cost=9.66..25.75 rows=1 width=478) (actual time=2.310..2.341 rows=0 loops=1)
         Hash Cond: (c.id = t_1.id)

-- 1000
Hash Join
  (cost=9.66..129.65 rows=5 width=478) (actual time=1.640..1.693 rows=0 loops=1)
         Hash Cond: (c.id = t_1.id)

-- 10000
Hash Join
  (cost=9.66..1209.58 rows=50 width=478) (actual time=176127.315..176127.358 rows=0 loops=1)
         Hash Cond: (c.id = t_1.id)
```

<v-click>

Abbiamo 184 __Hash Join__, ma per ogni Hash Join scannerizza tutte le partizioni giornaliere. Il comportamento e' esponenziale.
</v-click>