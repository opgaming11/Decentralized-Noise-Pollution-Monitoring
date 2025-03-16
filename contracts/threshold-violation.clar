;; Threshold Violation Contract
;; Identifies excessive noise events

(define-data-var admin principal tx-sender)

;; Map of threshold configurations by zone
(define-map thresholds
  { zone-id: (string-ascii 32) }
  {
    day-limit: uint,    ;; Daytime noise limit in decibels
    night-limit: uint,  ;; Nighttime noise limit in decibels
    day-start: uint,    ;; Hour when day starts (0-23)
    day-end: uint       ;; Hour when day ends (0-23)
  }
)

;; Map of recorded violations
(define-map violations
  {
    violation-id: uint
  }
  {
    sensor-id: (string-ascii 32),
    zone-id: (string-ascii 32),
    timestamp: uint,
    decibel-level: uint,
    threshold: uint,
    resolved: bool
  }
)

;; Counter for violation IDs
(define-data-var violation-counter uint u0)

;; Set threshold for a zone
(define-public (set-threshold
    (zone-id (string-ascii 32))
    (day-limit uint)
    (night-limit uint)
    (day-start uint)
    (day-end uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (< day-start u24) (err u400))
    (asserts! (< day-end u24) (err u400))

    (map-set thresholds
      { zone-id: zone-id }
      {
        day-limit: day-limit,
        night-limit: night-limit,
        day-start: day-start,
        day-end: day-end
      }
    )
    (ok true)
  )
)

;; Check if a reading violates the threshold and record if it does
(define-public (check-violation
    (sensor-id (string-ascii 32))
    (zone-id (string-ascii 32))
    (decibel-level uint)
    (hour uint))
  (let (
      (zone-thresholds (unwrap! (map-get? thresholds { zone-id: zone-id }) (err u404)))
      (is-daytime (and (>= hour (get day-start zone-thresholds)) (< hour (get day-end zone-thresholds))))
      (current-threshold (if is-daytime (get day-limit zone-thresholds) (get night-limit zone-thresholds)))
      (timestamp (unwrap-panic (get-block-info? time u0)))
    )

    ;; Check if the reading exceeds the threshold
    (if (> decibel-level current-threshold)
      (let ((violation-id (var-get violation-counter)))
        ;; Record the violation
        (map-insert violations
          { violation-id: violation-id }
          {
            sensor-id: sensor-id,
            zone-id: zone-id,
            timestamp: timestamp,
            decibel-level: decibel-level,
            threshold: current-threshold,
            resolved: false
          }
        )

        ;; Increment the violation counter
        (var-set violation-counter (+ violation-id u1))

        (ok violation-id)
      )
      (ok u0) ;; No violation
    )
  )
)

;; Mark a violation as resolved
(define-public (resolve-violation (violation-id uint))
  (let ((violation (unwrap! (map-get? violations { violation-id: violation-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set violations
      { violation-id: violation-id }
      (merge violation { resolved: true })
    )

    (ok true)
  )
)

;; Get threshold for a zone
(define-read-only (get-zone-threshold (zone-id (string-ascii 32)))
  (map-get? thresholds { zone-id: zone-id })
)

;; Get violation details
(define-read-only (get-violation (violation-id uint))
  (map-get? violations { violation-id: violation-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

