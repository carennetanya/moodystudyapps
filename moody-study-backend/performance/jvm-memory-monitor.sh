#!/bin/bash
# ============================================================
# Moody Study Backend — JVM Memory Monitor (via Actuator)
# ============================================================
# Tool    : curl + Spring Actuator /actuator/metrics
# Target  : No heap exhaustion during 5-min load test
# Cara    : Jalankan script ini BERSAMAAN saat k6 berjalan
#           di terminal terpisah.
#
# Output  : jvm-memory-log.txt  — snapshot tiap 15 detik
#           jvm-memory-summary.txt — ringkasan akhir
#
# LANGKAH PAKAI:
#   Terminal 1: k6 run performance/p95-latency-user-journey.js
#   Terminal 2: bash performance/jvm-memory-monitor.sh
# ============================================================

BASE_URL="${BASE_URL:-http://localhost:8081}"
LOG_FILE="jvm-memory-log.txt"
SUMMARY_FILE="jvm-memory-summary.txt"
INTERVAL=15         # polling tiap 15 detik
DURATION=330        # 5 menit + 30 detik buffer = 330 detik

echo "============================================================" | tee "$LOG_FILE"
echo "Moody Study Backend — JVM Memory Monitor" | tee -a "$LOG_FILE"
echo "Base URL : $BASE_URL" | tee -a "$LOG_FILE"
echo "Interval : ${INTERVAL}s | Duration: ${DURATION}s" | tee -a "$LOG_FILE"
echo "Start    : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Verifikasi actuator bisa diakses sebelum mulai
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/actuator/health")
if [ "$HEALTH" != "200" ]; then
  echo "ERROR: Actuator tidak bisa diakses. Status HTTP: $HEALTH"
  echo "Pastikan:"
  echo "  1. Backend sudah berjalan di $BASE_URL"
  echo "  2. /actuator/** sudah permitAll di SecurityConfig.java"
  echo "  3. application.properties sudah ada: management.endpoints.web.exposure.include=health,metrics"
  exit 1
fi

echo "Actuator OK (HTTP 200). Mulai monitoring..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Header tabel
printf "%-25s %-15s %-15s %-15s %-15s\n" \
  "Timestamp" "Heap_Used(MB)" "Heap_Max(MB)" "Used%(heap)" "NonHeap_Used(MB)" | tee -a "$LOG_FILE"
printf "%-25s %-15s %-15s %-15s %-15s\n" \
  "-------------------------" "---------------" "---------------" "---------------" "----------------" | tee -a "$LOG_FILE"

MAX_HEAP_SEEN=0
EXHAUSTION_DETECTED=false
ELAPSED=0
SNAPSHOTS=0

while [ $ELAPSED -lt $DURATION ]; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  # Heap used (bytes → MB)
  HEAP_USED_BYTES=$(curl -s "$BASE_URL/actuator/metrics/jvm.memory.used?tag=area:heap" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['measurements'][0]['value'])" 2>/dev/null)

  # Heap max (bytes → MB)
  HEAP_MAX_BYTES=$(curl -s "$BASE_URL/actuator/metrics/jvm.memory.max?tag=area:heap" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['measurements'][0]['value'])" 2>/dev/null)

  # Non-heap used (bytes → MB)
  NONHEAP_USED_BYTES=$(curl -s "$BASE_URL/actuator/metrics/jvm.memory.used?tag=area:nonheap" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['measurements'][0]['value'])" 2>/dev/null)

  # Konversi ke MB
  HEAP_USED_MB=$(python3 -c "print(round(${HEAP_USED_BYTES:-0} / 1048576, 1))" 2>/dev/null || echo "N/A")
  HEAP_MAX_MB=$(python3 -c "print(round(${HEAP_MAX_BYTES:-0} / 1048576, 1))" 2>/dev/null || echo "N/A")
  NONHEAP_USED_MB=$(python3 -c "print(round(${NONHEAP_USED_BYTES:-0} / 1048576, 1))" 2>/dev/null || echo "N/A")

  # Persentase heap usage
  HEAP_PCT=$(python3 -c "
v=${HEAP_USED_BYTES:-0}; m=${HEAP_MAX_BYTES:-1}
print(round(v/m*100, 1)) if m > 0 else print('N/A')
" 2>/dev/null || echo "N/A")

  printf "%-25s %-15s %-15s %-15s %-15s\n" \
    "$TIMESTAMP" "$HEAP_USED_MB" "$HEAP_MAX_MB" "$HEAP_PCT%" "$NONHEAP_USED_MB" | tee -a "$LOG_FILE"

  # Track heap max tertinggi
  if [ "$HEAP_USED_MB" != "N/A" ]; then
    IS_HIGHER=$(python3 -c "print('yes' if ${HEAP_USED_MB} > ${MAX_HEAP_SEEN} else 'no')" 2>/dev/null)
    if [ "$IS_HIGHER" = "yes" ]; then
      MAX_HEAP_SEEN=$HEAP_USED_MB
    fi
  fi

  # Deteksi heap exhaustion: usage >= 95% dari max
  if [ "$HEAP_PCT" != "N/A" ]; then
    IS_EXHAUSTED=$(python3 -c "print('yes' if ${HEAP_PCT} >= 95 else 'no')" 2>/dev/null)
    if [ "$IS_EXHAUSTED" = "yes" ]; then
      EXHAUSTION_DETECTED=true
      echo "⚠ WARNING: Heap usage ${HEAP_PCT}% >= 95% — potensi heap exhaustion!" | tee -a "$LOG_FILE"
    fi
  fi

  SNAPSHOTS=$((SNAPSHOTS + 1))
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo "SELESAI: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "Total snapshot  : $SNAPSHOTS" | tee -a "$LOG_FILE"
echo "Max heap dilihat: ${MAX_HEAP_SEEN} MB" | tee -a "$LOG_FILE"

if [ "$EXHAUSTION_DETECTED" = true ]; then
  echo "Heap exhaustion : TERDETEKSI ✗ — ada snapshot >= 95% heap" | tee -a "$LOG_FILE"
  RESULT="FAIL ✗"
else
  echo "Heap exhaustion : TIDAK TERDETEKSI ✓" | tee -a "$LOG_FILE"
  RESULT="PASS ✓"
fi

echo "OVERALL RESULT  : $RESULT" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"

# Buat summary file terpisah
cat > "$SUMMARY_FILE" << EOF
Moody Study Backend — JVM Memory Under Load Summary
====================================================
Tool        : Spring Actuator /actuator/metrics
Metric      : jvm.memory.used (heap), jvm.memory.max (heap)
Threshold   : No heap exhaustion during 5-min load test
Load script : p95-latency-user-journey.js (50 VU, 5 menit)

Max heap used selama test : ${MAX_HEAP_SEEN} MB
Heap exhaustion detected  : ${EXHAUSTION_DETECTED}
OVERALL                   : $RESULT
EOF

echo ""
echo "Log tersimpan di  : $LOG_FILE"
echo "Summary tersimpan : $SUMMARY_FILE"