# OpenEdge Latch & Database Metrics Guide

## 1. What is a latch?

A latch is a **very fast internal lock** used by the database to protect shared memory structures.

Whenever a process needs to read or modify shared data:
1. It must acquire the latch
2. Perform its operation
3. Release the latch

If another process already holds it:
- The process retries (this is called **spinning**)
- If it still cannot get it, it sleeps briefly (**nap**)
- Then retries again

👉 When this repeats frequently, it creates **waiting**, which slows down the system.

---

## 2. What is Latch Contention?

Latch contention happens when:
> Multiple processes try to access the same resource at the same time

When contention occurs:
- Some processes are working
- Others are waiting

👉 The more waiting, the worse performance becomes

---

## 3. How Latches Behave Internally (Important Insight)

From MDBA internals:

Each latch tracks:
- Lock attempts
- Busy events (already locked)
- Spin retries (CPU work)
- Waits (naps) ✅ **most important**

### Acquisition lifecycle

```
Request latch
   ↓
Busy? → yes
   ↓
Spin (retry loop)
   ↓
Still busy → sleep (nap)
   ↓
Retry
```

👉 **Spins consume CPU**
👉 **Waits indicate real performance problems**

---

## 4. The Most Important Metric: Wait Ratio

```
Wait Ratio = Waits / Requests × 100
```

| Ratio | Meaning |
|------|--------|
| <1% | Healthy |
| 1–5% | Monitor |
| >5% | Investigate |
| >10% | Bottleneck |

### Additional signals
- Naps/sec > 10 → system contention
- Any latch timeouts → investigate immediately

👉 Always prioritize **waits**, not raw counts

---

## 5. The System Model (CRITICAL)

Latches are not independent. They are part of a pipeline:

```
Application
   ↓
Transactions (TXQ / TXT)
   ↓
Serialization (MTX)
   ↓
Logging (BIB / AIB / LG)
   ↓
Buffer Cache (BUF / BHT / LRU)
   ↓
Disk
```

👉 Problems propagate through this chain

### Example
- Slow disk → BI backlog
- → MTX delays
- → TXQ buildup

Looks like transaction problem, but is actually disk

---

## 6. Latch Groups Explained (Plain English)

### 🔴 Transactions & Logging Path

| Latch | What it protects | What high values mean |
|------|-----------------|----------------------|
| TXQ | Transaction queue | Too many concurrent commits |
| TXT | Transaction table | Many active transactions |
| MTX | Global ordering | Serialization bottleneck |
| BIB | Before-image buffers | Logging pressure |
| AIB | After-image buffers | Journal pressure |
| LG  | Log file sync | Disk sync latency |

👉 These represent "saving work" in the database

---

### 🧠 Buffer Cache & Data Access (MOST IMPORTANT)

| Latch | What it protects | What high values mean |
|------|-----------------|----------------------|
| BUF | Data buffers | Hot data / contention |
| BHT | Buffer lookup | Cache inefficiency |
| LRU | Cache eviction | Too much churn |
| PWQ | Page writer queue | Dirty page backlog |
| CPQ | Checkpoint queue | Checkpoint pressure |
| BFP | Buffer pool control | Overall cache stress |

👉 These represent "reading and writing data"

---

### 🔒 Locking Subsystem

| Latch | Purpose |
|------|--------|
| LKT (LHT*) | Lock hash chains |
| LKF | Lock allocation |
| LKP | Lock cleanup |

👉 Usually not the root cause

---

### 🧩 Metadata & Session

| Latch | Purpose |
|------|--------|
| USR | Connection tracking |
| OM | Object mapping |
| SCC | Schema cache |
| SEQ | Sequence generator |
| EC | Encryption cache |

---

### ⚙️ Feature Latches

Only relevant if features used:
- CDC (change data capture)
- RPL (replication)
- SEC (security)
- DBN (notifications)

---

## 7. Latch Priority (Where to Look First)

### Tier 1 (Start here)
- BUF
- BIB
- TXQ
- MTX

### Tier 2
- BHT
- LRU
- PWQ / CPQ

### Tier 3 (Usually secondary)
- Locking
- Metadata

---

## 8. Mapping Latches to Real Problems

### Buffer Contention

Symptoms:
- BUF high
- Low buffer hit % (<95%)
- High reads/sec

Meaning:
> Not enough data is staying in memory

Fix:
- Increase `-B`
- Reduce hot data access

---

### BI / Logging Bottleneck

Symptoms:
- BIB high
- High BI writes

Meaning:
> Logging system overwhelmed or disk too slow

Fix:
- Increase `-bibufs`
- Improve disk performance

---

### Transaction Pressure

Symptoms:
- TXQ high
- High commits/sec

Meaning:
> Too many small transactions

Fix:
- Batch operations

---

### System Saturation

Symptoms:
- Many latch types high
- High waits overall

Meaning:
> Resource bottleneck (CPU/memory/disk)

Fix:
- Investigate system resources

---

## 9. Reading _latch Metrics

| Field | Meaning |
|------|--------|
| _latchlock | Number of requests |
| _latchbusy | Found locked |
| _latchspin | Spin retries |
| _latchwait | Waits (real contention) ✅ |

👉 Focus on `_latchwait`

---

## 10. Practical Troubleshooting Flowchart

```
Start
  ↓
Are latch waits high?
  ↓
Yes
  ↓
Identify highest wait latch

┌──────────────┬──────────────┬──────────────┐
│     BUF      │     BIB      │     TXQ      │
└─────┬────────┴─────┬────────┴─────┬────────┘
      ↓              ↓              ↓
 Cache issue    Logging issue    App issue

BUF:
  ↓
Buffer hit <95%?
  ↓
Yes → Increase -B

BIB:
  ↓
High BI writes?
  ↓
Yes → Increase -bibufs / check disk

TXQ:
  ↓
High commits?
  ↓
Yes → Batch transactions

If MANY latches are high:
  ↓
Check CPU / Memory / Disk
```

---

## 11. Tuning Parameters

| Parameter | Meaning | Recommendation |
|----------|---------|---------------|
| -spin | Retry attempts | ~5000 (test) |
| -nap | Initial sleep | 1 ms |
| -napmax | Max sleep | ≤ 500 ms |

⚠️ Too much spin increases CPU usage

---

## 12. Internal Latch Mapping (Addendum)

### Transaction / Logging
- MTL_MTX → MTX
- MTL_TXQ → TXQ
- MTL_TXT → TXT
- MTL_BIB → BIB
- MTL_AIB → AIB
- MTL_LG → LG

### Buffer System
- MTL_BF1–BF4 → BUF
- MTL_BHT → BHT
- MTL_LRU / LRU2 → LRU
- MTL_PWQ → PWQ
- MTL_CPQ → CPQ
- MTL_BFP → buffer control

### Locking
- MTL_LHT1–4 → LKT
- MTL_LKF → LKF
- MTL_LKP → LKP

### Metadata
- MTL_USR → USR
- MTL_OM → OM
- MTL_SCC → schema
- MTL_SEQ → sequence

### Features
- MTL_CDC → CDC
- MTL_SEC → security
- MTL_RPL → replication
- MTL_DBN → notifications

---

## 13. Final Takeaways

- Focus on WAITS, not counts
- Latches are symptoms, not root causes
- Start with BUF, BIB, TXQ, MTX
- Think in systems (pipeline), not isolated metrics
