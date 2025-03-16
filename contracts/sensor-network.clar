;; Sensor Network Contract
;; Manages data from sound monitoring devices

(define-data-var admin principal tx-sender)

;; Map of sensor IDs to their information
(define-map sensors
  { sensor-id: (string-ascii 32) }
  {
    owner: principal,
    location: (string-ascii 100),
    active: bool,
    last-reading: uint,
    last-updated: uint
  }
)

;; Map of sensor readings
(define-map sensor-readings
  {
    sensor-id: (string-ascii 32),
    timestamp: uint
  }
  {
    decibel-level: uint,
    frequency-data: (string-ascii 256),
    metadata: (string-ascii 256)
  }
)

;; Register a new sensor
(define-public (register-sensor (sensor-id (string-ascii 32)) (location (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-insert sensors
      { sensor-id: sensor-id }
      {
        owner: tx-sender,
        location: location,
        active: true,
        last-reading: u0,
        last-updated: (unwrap-panic (get-block-info? time u0))
      }
    )
    (ok true)
  )
)

;; Submit a sensor reading
(define-public (submit-reading
    (sensor-id (string-ascii 32))
    (decibel-level uint)
    (frequency-data (string-ascii 256))
    (metadata (string-ascii 256)))
  (let ((sensor-info (unwrap! (map-get? sensors { sensor-id: sensor-id }) (err u404)))
        (timestamp (unwrap-panic (get-block-info? time u0))))
    (asserts! (is-eq tx-sender (get owner sensor-info)) (err u403))
    (asserts! (get active sensor-info) (err u403))

    ;; Update the sensor's last reading info
    (map-set sensors
      { sensor-id: sensor-id }
      (merge sensor-info {
        last-reading: decibel-level,
        last-updated: timestamp
      })
    )

    ;; Store the reading
    (map-insert sensor-readings
      {
        sensor-id: sensor-id,
        timestamp: timestamp
      }
      {
        decibel-level: decibel-level,
        frequency-data: frequency-data,
        metadata: metadata
      }
    )

    (ok timestamp)
  )
)

;; Get a sensor reading
(define-read-only (get-reading (sensor-id (string-ascii 32)) (timestamp uint))
  (map-get? sensor-readings { sensor-id: sensor-id, timestamp: timestamp })
)

;; Get sensor info
(define-read-only (get-sensor-info (sensor-id (string-ascii 32)))
  (map-get? sensors { sensor-id: sensor-id })
)

;; Deactivate a sensor
(define-public (deactivate-sensor (sensor-id (string-ascii 32)))
  (let ((sensor-info (unwrap! (map-get? sensors { sensor-id: sensor-id }) (err u404))))
    (asserts! (or (is-eq tx-sender (get owner sensor-info)) (is-eq tx-sender (var-get admin))) (err u403))

    (map-set sensors
      { sensor-id: sensor-id }
      (merge sensor-info { active: false })
    )

    (ok true)
  )
)

;; Activate a sensor
(define-public (activate-sensor (sensor-id (string-ascii 32)))
  (let ((sensor-info (unwrap! (map-get? sensors { sensor-id: sensor-id }) (err u404))))
    (asserts! (or (is-eq tx-sender (get owner sensor-info)) (is-eq tx-sender (var-get admin))) (err u403))

    (map-set sensors
      { sensor-id: sensor-id }
      (merge sensor-info { active: true })
    )

    (ok true)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
