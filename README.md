# Brazil / Europe ANS Performance Dashboard

Dashboard interativo em R Shiny para comparação de desempenho operacional de
Navegação Aérea entre Brasil (DECEA) e Europa (EUROCONTROL), cobrindo o período
de 2019 a 2025.

---

## Início Rápido

```r
# 1. Instalar pacotes (somente na primeira vez)
source("setup.R")

# 2. Iniciar o dashboard
shiny::runApp()
```

**Pacotes necessários:** `shiny`, `bslib`, `dplyr`, `tidyr`, `ggplot2`,
`lubridate`, `scales`, `DT`, `zoo`

---

## Estrutura do Projeto

```
Dashboard_BRA_EUR/
├── app.R                  # Aplicação Shiny principal
├── setup.R                # Instalador de pacotes
├── dashboard_guide.qmd    # Guia do dashboard (Quarto)
├── README.md              # Este arquivo
└── data/
    ├── PBWG-BRA-network-traffic-2023-2025.csv
    ├── PBWG-EUR-network-traffic-2023-2025.csv
    ├── PBWG-BRA-punc-2025.csv
    ├── PBWG-EUR-punc-2025.csv
    ├── PBWG-EUR-PUNC-2023.csv
    ├── PBWG-EUR-PUNC-2024.csv
    ├── PBWG-EUR-PUNC-LPPT-2019-2024.csv
    ├── PBWG-EUR-LGAV-punc-2024.csv
    ├── PBWG-BRA-EUR-bli-pli-2019-2025.csv
    ├── PBWG-BRA-txxt-analytic-2023-ref2024-icao_ganp_p20.csv
    ├── PBWG-BRA-txxt-analytic-2024-ref2024-icao_ganp_p20.csv
    ├── PBWG-BRA-txxt-analytic-2025-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-txxt-analytic-2023-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-txxt-analytic-2024-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-txxt-analytic-2025-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-asma40-monthly-2023-2025-public.csv
    ├── PBWG-BRA-EUR-ordered-throughput-LPPT-SBGR-2019-2025.csv
    ├── PBWG-BRA-EUR-bli-pli-2019-2025.csv
    ├── PBWG-BRA-EUR-study-flow-rank-2023-2025.csv
    ├── PBWG-BRA-EUR-study-flow-pairs-2023-2025.csv
    ├── PBWG-BRA-EUR-world-region-departures-2025.csv
    ├── PBWG-BRA-EUR-daio-share-2025.csv
    ├── PBWG-BRA-EUR-airport-departure-rank-2025.csv
    ├── PBWG-BRA-EUR-network-flow-pairs-2025.csv
    └── PBWG-BRA-EUR-country-departures-2025.csv
```

---

## Abas do Dashboard e Origem dos Dados

### 1. Overview
Visão geral com KPI cards, gráfico de tráfego diário e distribuição por tipo de voo.

| Elemento | Arquivo de dados |
|----------|-----------------|
| KPI – total de voos BRA e EUR | `PBWG-BRA-network-traffic-2023-2025.csv` / `PBWG-EUR-network-traffic-2023-2025.csv` |
| Gráfico – média móvel 7 dias | Mesmos arquivos acima (campo `FLTS`) |
| Gráfico – distribuição DAIO (Domestic/Arrival/International/Overflight) | `PBWG-BRA-EUR-daio-share-2025.csv` |

---

### 2. Traffic
Evolução do volume de tráfego diário e totais anuais, com filtros por região e segmento de voo.

| Elemento | Arquivo de dados |
|----------|-----------------|
| Tráfego diário (total, doméstico, chegadas, partidas, sobrevoos) | `PBWG-BRA-network-traffic-2023-2025.csv` / `PBWG-EUR-network-traffic-2023-2025.csv` |
| Tabela de totais anuais | Calculado a partir dos mesmos arquivos |

**Colunas relevantes:** `DATE`, `FLTS` (total), `D` (departures), `A` (arrivals),
`I` (intra-regional), `O` (overflights).

---

### 3. Punctuality
Distribuição de pontualidade de chegadas e partidas por aeroporto de estudo,
em cinco bandas: Early > 15 min, Early 5–15 min, Within ± 5 min, Late 5–15 min, Late > 15 min.

| Elemento | Arquivo de dados |
|----------|-----------------|
| Pontualidade BRA 2025 (ARR + DEP) | `PBWG-BRA-punc-2025.csv` |
| Pontualidade EUR 2025 | `PBWG-EUR-punc-2025.csv` |
| Pontualidade EUR 2024 | `PBWG-EUR-PUNC-2024.csv` + `PBWG-EUR-LGAV-punc-2024.csv` |
| Pontualidade EUR 2023 | `PBWG-EUR-PUNC-2023.csv` |
| Histórico LPPT 2019–2024 | `PBWG-EUR-PUNC-LPPT-2019-2024.csv` |

**Formato dos arquivos:** cada linha é um aeroporto × data × fase (ARR/DEP), com
contagens por bucket de minuto de `(-INF,-60]` a `[60,INF)`. O app agrega esses
buckets nas cinco bandas padrão do relatório PBWG.

---

### 4. Capacity
Capacidade declarada de pico e índices de utilização (BLI e PLI) por aeroporto,
para o período 2019–2025.

| Elemento | Arquivo de dados |
|----------|-----------------|
| Capacidade máxima declarada (`MAX_CAP`) | `PBWG-BRA-EUR-bli-pli-2019-2025.csv` |
| Busy-Level Index (`BLI`) – horas acima de 20% da capacidade | Mesmo arquivo |
| Peak-Level Index (`PLI`) – horas acima de 80% da capacidade | Mesmo arquivo |

**Colunas relevantes:** `ICAO`, `YEAR`, `MAX_CAP`, `BLI`, `PLI`, `REG`.

---

### 5. Taxi & ASMA
Tempos adicionais de superfície (taxi-out e taxi-in) e de sequenciamento de chegadas
(ASMA), calculados como desvio em relação ao tempo de referência não impedido.

| Elemento | Arquivo de dados |
|----------|-----------------|
| Taxi-out adicional BRA (2023–2025) | `PBWG-BRA-txxt-analytic-2023/2024/2025-ref2024-icao_ganp_p20.csv` – fase DEP |
| Taxi-in adicional BRA (2023–2025) | Mesmo conjunto de arquivos – fase ARR |
| Taxi-out/in adicional EUR (2023–2025) | `PBWG-EUR-txxt-analytic-2023/2024/2025-ref2024-icao_ganp_p20.csv` |
| ASMA adicional EUR (mensal, 2023–2025) | `PBWG-EUR-asma40-monthly-2023-2025-public.csv` |

**Colunas relevantes:** `ICAO`, `PHASE` (ARR/DEP), `DATE`, `MVTS_VALID`,
`TOT_ADD_TIME`. O tempo médio adicional por voo é calculado como
`TOT_ADD_TIME / MVTS_VALID`.

> **Nota:** dados de ASMA para o Brasil não estão disponíveis nesta versão.

---

### 6. BRA-EUR Flows
Conexões inter-regionais entre Brasil e Europa, ranking de pares de rotas de
estudo e distribuição de tráfego por região do mundo.

| Elemento | Arquivo de dados |
|----------|-----------------|
| Rank de pares de rotas (aeroportos de estudo, 2023–2025) | `PBWG-BRA-EUR-study-flow-rank-2023-2025.csv` |
| Conexões internacionais por região do mundo 2025 | `PBWG-BRA-EUR-world-region-departures-2025.csv` |

---

### 7. Airport Comparison
Comparação direta entre um aeroporto brasileiro e um europeu: distribuição de
pontualidade e curva de throughput ordenado por hora.

| Elemento | Arquivo de dados |
|----------|-----------------|
| Pontualidade por aeroporto | Mesmos arquivos da aba Punctuality |
| Curva de throughput (SBGR e LPPT, 2019–2025) | `PBWG-BRA-EUR-ordered-throughput-LPPT-SBGR-2019-2025.csv` |

> **Nota:** a curva de throughput ordenado está disponível apenas para SBGR
> (Guarulhos) e LPPT (Lisboa) nesta versão.

---

### 8. Data
Tabelas brutas de todos os conjuntos de dados carregados, disponíveis para
inspeção e exportação diretamente no navegador.

---

## Aeroportos de Estudo

**Brasil (12):**
SBBR · SBCF · SBCT · SBEG · SBGL · SBGR · SBKP · SBPA · SBRF · SBRJ · SBSP · SBSV

**Europa (12):**
EDDF · EDDM · EGKK · EGLL · EHAM · LEBL · LEMD · LFPG · LGAV · LPPT · LSZH · LTFM

---

## Atualização dos Dados

Os dados em `data/` foram extraídos do relatório conjunto DECEA–EUROCONTROL
*"Comparison of Operational Air Navigation System Performance 2019–2025"*.

Futuramente, scripts R dedicados serão adicionados a este repositório para
**regenerar automaticamente** cada arquivo CSV a partir das fontes de dados
originais (bases de dados DECEA e PRU/EUROCONTROL), mantendo o dashboard
sempre atualizado sem necessidade de edição manual.

---

## Fonte

> DECEA / EUROCONTROL Performance Review Unit — *Comparison of Operational
> Air Navigation System Performance: Brazil / Europe, 2019–2025*.
> Performance Benchmarking Working Group (PBWG).
