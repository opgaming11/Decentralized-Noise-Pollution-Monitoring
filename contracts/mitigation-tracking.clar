;; Mitigation Tracking Contract
;; Monitors effectiveness of noise reduction efforts

(define-data-var admin principal tx-sender)

;; Map of mitigation plans
(define-map mitigation-plans
  { plan-id: (string-ascii 32) }
  {
    source-id: (string-ascii 32),
    description: (string-ascii 256),
    start-date: uint,
    end-date: uint,
    status: (string-ascii 20),  ;; "planned", "in-progress", "completed", "failed"
    created-by: principal
  }
)

;; Map of mitigation actions
(define-map mitigation-actions
  { action-id: uint }
  {
    plan-id: (string-ascii 32),
    description: (string-ascii 256),
    date: uint,
    performed-by: principal,
    cost: uint,
    effectiveness-rating: (optional uint)  ;; 0-100 rating
  }
)

;; Map of before/after measurements
(define-map effectiveness-measurements
  { measurement-id: uint }
  {
    plan-id: (string-ascii 32),
    before-level: uint,  ;; decibel level before mitigation
    after-level: uint,   ;; decibel level after mitigation
    measurement-date: uint,
    measured-by: principal,
    notes: (string-ascii 256)
  }
)

;; Counters for IDs
(define-data-var action-counter uint u0)
(define-data-var measurement-counter uint u0)

;; Create a new mitigation plan
(define-public (create-mitigation-plan
    (plan-id (string-ascii 32))
    (source-id (string-ascii 32))
    (description (string-ascii 256))
    (start-date uint)
    (end-date uint))
  (begin
    (asserts! (>= end-date start-date) (err u400))

    (map-insert mitigation-plans
      { plan-id: plan-id }
      {
        source-id: source-id,
        description: description,
        start-date: start-date,
        end-date: end-date,
        status: "planned",
        created-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Update plan status
(define-public (update-plan-status (plan-id (string-ascii 32)) (status (string-ascii 20)))
  (let ((plan (unwrap! (map-get? mitigation-plans { plan-id: plan-id }) (err u404))))
    (asserts! (or
      (is-eq tx-sender (var-get admin))
      (is-eq tx-sender (get created-by plan))
    ) (err u403))

    ;; Validate status
    (asserts! (or
      (is-eq status "planned")
      (is-eq status "in-progress")
      (is-eq status "completed")
      (is-eq status "failed")
    ) (err u400))

    (map-set mitigation-plans
      { plan-id: plan-id }
      (merge plan { status: status })
    )

    (ok true)
  )
)

;; Record a mitigation action
(define-public (record-mitigation-action
    (plan-id (string-ascii 32))
    (description (string-ascii 256))
    (cost uint))
  (let ((action-id (var-get action-counter))
        (timestamp (unwrap-panic (get-block-info? time u0))))

    ;; Ensure the plan exists
    (asserts! (is-some (map-get? mitigation-plans { plan-id: plan-id })) (err u404))

    ;; Record the action
    (map-insert mitigation-actions
      { action-id: action-id }
      {
        plan-id: plan-id,
        description: description,
        date: timestamp,
        performed-by: tx-sender,
        cost: cost,
        effectiveness-rating: none
      }
    )

    ;; Increment the action counter
    (var-set action-counter (+ action-id u1))

    (ok action-id)
  )
)

;; Rate the effectiveness of an action
(define-public (rate-action-effectiveness (action-id uint) (rating uint))
  (let ((action (unwrap! (map-get? mitigation-actions { action-id: action-id }) (err u404))))
    (asserts! (<= rating u100) (err u400))

    (map-set mitigation-actions
      { action-id: action-id }
      (merge action { effectiveness-rating: (some rating) })
    )

    (ok true)
  )
)

;; Record before/after measurements
(define-public (record-effectiveness-measurement
    (plan-id (string-ascii 32))
    (before-level uint)
    (after-level uint)
    (notes (string-ascii 256)))
  (let ((measurement-id (var-get measurement-counter))
        (timestamp (unwrap-panic (get-block-info? time u0))))

    ;; Ensure the plan exists
    (asserts! (is-some (map-get? mitigation-plans { plan-id: plan-id })) (err u404))

    ;; Record the measurement
    (map-insert effectiveness-measurements
      { measurement-id: measurement-id }
      {
        plan-id: plan-id,
        before-level: before-level,
        after-level: after-level,
        measurement-date: timestamp,
        measured-by: tx-sender,
        notes: notes
      }
    )

    ;; Increment the measurement counter
    (var-set measurement-counter (+ measurement-id u1))

    (ok measurement-id)
  )
)

;; Get plan details
(define-read-only (get-mitigation-plan (plan-id (string-ascii 32)))
  (map-get? mitigation-plans { plan-id: plan-id })
)

;; Get action details
(define-read-only (get-mitigation-action (action-id uint))
  (map-get? mitigation-actions { action-id: action-id })
)

;; Get measurement details
(define-read-only (get-effectiveness-measurement (measurement-id uint))
  (map-get? effectiveness-measurements { measurement-id: measurement-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

