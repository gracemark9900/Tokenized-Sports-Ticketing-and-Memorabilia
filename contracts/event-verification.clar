;; Event Verification Contract
;; Validates legitimate sporting events

(define-data-var last-event-id uint u0)

;; Event data structure
(define-map events
  { event-id: uint }
  {
    name: (string-ascii 100),
    venue: (string-ascii 100),
    date: uint,
    organizer: principal,
    verified: bool
  }
)

;; Event organizers
(define-map event-organizers
  { organizer: principal }
  { authorized: bool }
)

;; Initialize contract owner
(define-constant contract-owner tx-sender)

;; Error codes
(define-constant err-not-authorized u100)
(define-constant err-event-not-found u101)
(define-constant err-already-verified u102)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

;; Add an event organizer
(define-public (add-event-organizer (organizer principal))
  (begin
    (asserts! (is-contract-owner) (err u1))
    (ok (map-set event-organizers { organizer: organizer } { authorized: true }))
  )
)

;; Check if caller is authorized organizer
(define-private (is-authorized-organizer)
  (default-to false (get authorized (map-get? event-organizers { organizer: tx-sender })))
)

;; Register a new sporting event
(define-public (register-event (name (string-ascii 100)) (venue (string-ascii 100)) (date uint))
  (let
    (
      (new-id (+ (var-get last-event-id) u1))
    )
    (asserts! (or (is-contract-owner) (is-authorized-organizer)) (err err-not-authorized))
    (map-set events
      { event-id: new-id }
      {
        name: name,
        venue: venue,
        date: date,
        organizer: tx-sender,
        verified: false
      }
    )
    (var-set last-event-id new-id)
    (ok new-id)
  )
)

;; Verify an event
(define-public (verify-event (event-id uint))
  (let
    (
      (event (map-get? events { event-id: event-id }))
    )
    (asserts! (is-contract-owner) (err err-not-authorized))
    (asserts! (is-some event) (err err-event-not-found))
    (asserts! (not (get verified (unwrap-panic event))) (err err-already-verified))
    (ok (map-set events
      { event-id: event-id }
      (merge (unwrap-panic event) { verified: true })
    ))
  )
)

;; Check if an event is verified
(define-read-only (is-event-verified (event-id uint))
  (default-to false (get verified (map-get? events { event-id: event-id })))
)

;; Get event details
(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)
