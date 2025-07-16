;; Escalation Manager Verification Contract
;; Validates and manages customer service escalation managers

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MANAGER-NOT-FOUND (err u101))
(define-constant ERR-MANAGER-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-INPUT (err u103))

;; Data Variables
(define-data-var next-manager-id uint u1)

;; Data Maps
(define-map managers
  { manager-id: uint }
  {
    principal: principal,
    name: (string-ascii 50),
    specialization: (string-ascii 100),
    experience-level: uint,
    active: bool,
    total-cases: uint,
    success-rate: uint,
    created-block: uint
  }
)

(define-map manager-principals
  { principal: principal }
  { manager-id: uint }
)

;; Public Functions

;; Register a new escalation manager
(define-public (register-manager (name (string-ascii 50)) (specialization (string-ascii 100)) (experience-level uint))
  (let ((manager-id (var-get next-manager-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len specialization) u0) ERR-INVALID-INPUT)
    (asserts! (< experience-level u11) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? manager-principals { principal: tx-sender })) ERR-MANAGER-ALREADY-EXISTS)

    (map-set managers
      { manager-id: manager-id }
      {
        principal: tx-sender,
        name: name,
        specialization: specialization,
        experience-level: experience-level,
        active: true,
        total-cases: u0,
        success-rate: u100,
        created-block: block-height
      }
    )

    (map-set manager-principals
      { principal: tx-sender }
      { manager-id: manager-id }
    )

    (var-set next-manager-id (+ manager-id u1))
    (ok manager-id)
  )
)

;; Update manager status
(define-public (update-manager-status (manager-id uint) (active bool))
  (let ((manager (unwrap! (map-get? managers { manager-id: manager-id }) ERR-MANAGER-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set managers
      { manager-id: manager-id }
      (merge manager { active: active })
    )
    (ok true)
  )
)

;; Update manager performance metrics
(define-public (update-manager-metrics (manager-id uint) (total-cases uint) (success-rate uint))
  (let ((manager (unwrap! (map-get? managers { manager-id: manager-id }) ERR-MANAGER-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= success-rate u100) ERR-INVALID-INPUT)

    (map-set managers
      { manager-id: manager-id }
      (merge manager {
        total-cases: total-cases,
        success-rate: success-rate
      })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get manager details
(define-read-only (get-manager (manager-id uint))
  (map-get? managers { manager-id: manager-id })
)

;; Get manager ID by principal
(define-read-only (get-manager-id (principal principal))
  (map-get? manager-principals { principal: principal })
)

;; Check if manager is active
(define-read-only (is-manager-active (manager-id uint))
  (match (map-get? managers { manager-id: manager-id })
    manager (get active manager)
    false
  )
)

;; Get total number of managers
(define-read-only (get-total-managers)
  (- (var-get next-manager-id) u1)
)
