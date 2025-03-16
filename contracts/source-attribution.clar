;; Source Attribution Contract
;; Helps identify origins of noise pollution

(define-data-var admin principal tx-sender)

;; Map of known noise sources
(define-map noise-sources
  { source-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    type: (string-ascii 50),
    owner: (optional principal),
    registered-by: principal
  }
)

;; Map of attributions linking violations to sources
(define-map attributions
  { attribution-id: uint }
  {
    violation-id: uint,
    source-id: (string-ascii 32),
    confidence: uint,  ;; 0-100 confidence level
    evidence: (string-ascii 256),
    attributed-by: principal,
    timestamp: uint
  }
)

;; Counter for attribution IDs
(define-data-var attribution-counter uint u0)

;; Register a new noise source
(define-public (register-source
    (source-id (string-ascii 32))
    (name (string-ascii 100))
    (location (string-ascii 100))
    (type (string-ascii 50))
    (owner (optional principal)))
  (begin
    (map-insert noise-sources
      { source-id: source-id }
      {
        name: name,
        location: location,
        type: type,
        owner: owner,
        registered-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Create an attribution linking a violation to a source
(define-public (create-attribution
    (violation-id uint)
    (source-id (string-ascii 32))
    (confidence uint)
    (evidence (string-ascii 256)))
  (let ((attribution-id (var-get attribution-counter))
        (timestamp (unwrap-panic (get-block-info? time u0))))

    ;; Ensure the source exists
    (asserts! (is-some (map-get? noise-sources { source-id: source-id })) (err u404))

    ;; Ensure confidence is between 0 and 100
    (asserts! (<= confidence u100) (err u400))

    ;; Create the attribution
    (map-insert attributions
      { attribution-id: attribution-id }
      {
        violation-id: violation-id,
        source-id: source-id,
        confidence: confidence,
        evidence: evidence,
        attributed-by: tx-sender,
        timestamp: timestamp
      }
    )

    ;; Increment the attribution counter
    (var-set attribution-counter (+ attribution-id u1))

    (ok attribution-id)
  )
)

;; Get source information
(define-read-only (get-source (source-id (string-ascii 32)))
  (map-get? noise-sources { source-id: source-id })
)

;; Get attribution details
(define-read-only (get-attribution (attribution-id uint))
  (map-get? attributions { attribution-id: attribution-id })
)

;; Update source information (admin or original registrant only)
(define-public (update-source
    (source-id (string-ascii 32))
    (name (string-ascii 100))
    (location (string-ascii 100))
    (type (string-ascii 50)))
  (let ((source (unwrap! (map-get? noise-sources { source-id: source-id }) (err u404))))
    (asserts! (or
      (is-eq tx-sender (var-get admin))
      (is-eq tx-sender (get registered-by source))
    ) (err u403))

    (map-set noise-sources
      { source-id: source-id }
      (merge source {
        name: name,
        location: location,
        type: type
      })
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

