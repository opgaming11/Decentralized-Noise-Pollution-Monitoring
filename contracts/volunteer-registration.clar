;; Volunteer Registration Contract
;; Manages volunteer identities and skills

;; Define data variables
(define-data-var admin principal tx-sender)
(define-map volunteers
  { id: principal }
  {
    name: (string-utf8 100),
    email: (string-utf8 100),
    skills: (list 10 (string-utf8 50)),
    registered: uint,
    active: bool
  }
)

;; Read-only functions
(define-read-only (get-admin)
  (var-get admin)
)

(define-read-only (get-volunteer (id principal))
  (map-get? volunteers { id: id })
)

(define-read-only (is-volunteer (id principal))
  (is-some (map-get? volunteers { id: id }))
)

;; Public functions
(define-public (register-volunteer (name (string-utf8 100)) (email (string-utf8 100)) (skills (list 10 (string-utf8 50))))
  (let ((id tx-sender))
    (if (is-volunteer id)
      (err u1) ;; Already registered
      (ok (map-set volunteers
        { id: id }
        {
          name: name,
          email: email,
          skills: skills,
          registered: block-height,
          active: true
        }
      ))
    )
  )
)

(define-public (update-skills (skills (list 10 (string-utf8 50))))
  (let ((id tx-sender))
    (if (is-volunteer id)
      (ok (map-set volunteers
        { id: id }
        (merge (unwrap-panic (get-volunteer id))
          { skills: skills }
        )
      ))
      (err u2) ;; Not found
    )
  )
)

(define-public (deactivate-volunteer (id principal))
  (if (is-eq tx-sender (var-get admin))
    (if (is-volunteer id)
      (ok (map-set volunteers
        { id: id }
        (merge (unwrap-panic (get-volunteer id))
          { active: false }
        )
      ))
      (err u2) ;; Not found
    )
    (err u3) ;; Unauthorized
  )
)

(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (var-set admin new-admin))
    (err u3) ;; Unauthorized
  )
)
