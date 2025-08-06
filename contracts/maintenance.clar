;; Property Maintenance and Code Enforcement Contract
;; Ensures properties meet safety and maintenance standards

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-PROPERTY-NOT-FOUND (err u401))
(define-constant ERR-VIOLATION-NOT-FOUND (err u402))
(define-constant ERR-INSPECTION-NOT-FOUND (err u403))
(define-constant ERR-INVALID-STATUS (err u404))
(define-constant ERR-INVALID-INPUT (err u405))

;; Data Variables
(define-data-var next-violation-id uint u1)
(define-data-var next-inspection-id uint u1)
(define-data-var next-work-order-id uint u1)

;; Data Maps
(define-map maintenance-properties
  { property-id: uint }
  {
    address: (string-ascii 200),
    owner: principal,
    property-type: (string-ascii 50),
    last-inspection: uint,
    compliance-status: (string-ascii 20),
    maintenance-score: uint,
    active-violations: uint
  }
)

(define-map code-violations
  { violation-id: uint }
  {
    property-id: uint,
    violation-type: (string-ascii 100),
    description: (string-ascii 500),
    severity: (string-ascii 20),
    reported-date: uint,
    reporter: principal,
    status: (string-ascii 20),
    correction-deadline: uint,
    fine-amount: uint,
    corrected-date: (optional uint)
  }
)

(define-map inspections
  { inspection-id: uint }
  {
    property-id: uint,
    inspector: principal,
    inspection-date: uint,
    inspection-type: (string-ascii 50),
    findings: (list 20 (string-ascii 200)),
    violations-found: (list 10 uint),
    overall-rating: uint,
    next-inspection-due: uint,
    report-url: (optional (string-ascii 200))
  }
)

(define-map work-orders
  { work-order-id: uint }
  {
    property-id: uint,
    violation-id: (optional uint),
    work-type: (string-ascii 100),
    description: (string-ascii 500),
    priority: (string-ascii 20),
    assigned-contractor: (optional principal),
    estimated-cost: uint,
    status: (string-ascii 20),
    created-date: uint,
    completion-date: (optional uint)
  }
)

(define-map inspectors
  { inspector: principal }
  {
    authorized: bool,
    certification: (string-ascii 100),
    specializations: (list 5 (string-ascii 50)),
    certification-date: uint
  }
)

(define-map maintenance-standards
  { standard-id: (string-ascii 50) }
  {
    category: (string-ascii 100),
    description: (string-ascii 500),
    requirements: (list 10 (string-ascii 200)),
    inspection-frequency: uint,
    penalty-structure: (list 5 uint)
  }
)

;; Authorization Functions
(define-private (is-authorized (user principal))
  (or
    (is-eq user CONTRACT-OWNER)
    (default-to false (get authorized (map-get? inspectors { inspector: user })))
  )
)

(define-private (is-property-owner (user principal) (property-id uint))
  (match (map-get? maintenance-properties { property-id: property-id })
    property (is-eq user (get owner property))
    false
  )
)

;; Administrative Functions
(define-public (add-inspector
  (inspector principal)
  (certification (string-ascii 100))
  (specializations (list 5 (string-ascii 50)))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set inspectors
      { inspector: inspector }
      {
        authorized: true,
        certification: certification,
        specializations: specializations,
        certification-date: block-height
      }
    ))
  )
)

(define-public (set-maintenance-standard
  (standard-id (string-ascii 50))
  (category (string-ascii 100))
  (description (string-ascii 500))
  (requirements (list 10 (string-ascii 200)))
  (inspection-frequency uint)
  (penalty-structure (list 5 uint))
)
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> inspection-frequency u0) ERR-INVALID-INPUT)

    (map-set maintenance-standards
      { standard-id: standard-id }
      {
        category: category,
        description: description,
        requirements: requirements,
        inspection-frequency: inspection-frequency,
        penalty-structure: penalty-structure
      }
    )

    (ok true)
  )
)

;; Property Registration
(define-public (register-maintenance-property
  (property-id uint)
  (address (string-ascii 200))
  (owner principal)
  (property-type (string-ascii 50))
)
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)

    (map-set maintenance-properties
      { property-id: property-id }
      {
        address: address,
        owner: owner,
        property-type: property-type,
        last-inspection: u0,
        compliance-status: "pending",
        maintenance-score: u0,
        active-violations: u0
      }
    )

    (ok true)
  )
)

;; Inspection Functions
(define-public (schedule-inspection
  (property-id uint)
  (inspection-type (string-ascii 50))
  (inspection-date uint)
)
  (let
    (
      (property (unwrap! (map-get? maintenance-properties { property-id: property-id }) ERR-PROPERTY-NOT-FOUND))
      (inspection-id (var-get next-inspection-id))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= inspection-date block-height) ERR-INVALID-INPUT)

    (map-set inspections
      { inspection-id: inspection-id }
      {
        property-id: property-id,
        inspector: tx-sender,
        inspection-date: inspection-date,
        inspection-type: inspection-type,
        findings: (list),
        violations-found: (list),
        overall-rating: u0,
        next-inspection-due: u0,
        report-url: none
      }
    )

    (var-set next-inspection-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

(define-public (complete-inspection
  (inspection-id uint)
  (findings (list 20 (string-ascii 200)))
  (overall-rating uint)
  (next-inspection-due uint)
)
  (let
    (
      (inspection (unwrap! (map-get? inspections { inspection-id: inspection-id }) ERR-INSPECTION-NOT-FOUND))
      (property-id (get property-id inspection))
      (property (unwrap! (map-get? maintenance-properties { property-id: property-id }) ERR-PROPERTY-NOT-FOUND))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq tx-sender (get inspector inspection)) ERR-NOT-AUTHORIZED)
    (asserts! (<= overall-rating u100) ERR-INVALID-INPUT)

    ;; Update inspection record
    (map-set inspections
      { inspection-id: inspection-id }
      (merge inspection {
        findings: findings,
        overall-rating: overall-rating,
        next-inspection-due: next-inspection-due
      })
    )

    ;; Update property maintenance info
    (map-set maintenance-properties
      { property-id: property-id }
      (merge property {
        last-inspection: block-height,
        maintenance-score: overall-rating,
        compliance-status: (if (>= overall-rating u70) "compliant" "non-compliant")
      })
    )

    (ok overall-rating)
  )
)

;; Violation Management
(define-public (report-violation
  (property-id uint)
  (violation-type (string-ascii 100))
  (description (string-ascii 500))
  (severity (string-ascii 20))
)
  (let
    (
      (property (unwrap! (map-get? maintenance-properties { property-id: property-id }) ERR-PROPERTY-NOT-FOUND))
      (violation-id (var-get next-violation-id))
      (fine-amount (calculate-fine severity))
      (correction-deadline (+ block-height (get-correction-period severity)))
    )
    (asserts! (or (is-authorized tx-sender) (is-property-owner tx-sender property-id)) ERR-NOT-AUTHORIZED)

    (map-set code-violations
      { violation-id: violation-id }
      {
        property-id: property-id,
        violation-type: violation-type,
        description: description,
        severity: severity,
        reported-date: block-height,
        reporter: tx-sender,
        status: "open",
        correction-deadline: correction-deadline,
        fine-amount: fine-amount,
        corrected-date: none
      }
    )

    ;; Update property violation count
    (map-set maintenance-properties
      { property-id: property-id }
      (merge property {
        active-violations: (+ (get active-violations property) u1),
        compliance-status: "non-compliant"
      })
    )

    (var-set next-violation-id (+ violation-id u1))
    (ok violation-id)
  )
)

(define-public (resolve-violation (violation-id uint))
  (let
    (
      (violation (unwrap! (map-get? code-violations { violation-id: violation-id }) ERR-VIOLATION-NOT-FOUND))
      (property-id (get property-id violation))
      (property (unwrap! (map-get? maintenance-properties { property-id: property-id }) ERR-PROPERTY-NOT-FOUND))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status violation) "open") ERR-INVALID-STATUS)

    ;; Update violation status
    (map-set code-violations
      { violation-id: violation-id }
      (merge violation {
        status: "resolved",
        corrected-date: (some block-height)
      })
    )

    ;; Update property violation count
    (let
      (
        (new-violation-count (if (> (get active-violations property) u0)
                            (- (get active-violations property) u1)
                            u0))
      )
      (map-set maintenance-properties
        { property-id: property-id }
        (merge property {
          active-violations: new-violation-count,
          compliance-status: (if (is-eq new-violation-count u0) "compliant" "non-compliant")
        })
      )
    )

    (ok true)
  )
)

;; Work Order Management
(define-public (create-work-order
  (property-id uint)
  (violation-id (optional uint))
  (work-type (string-ascii 100))
  (description (string-ascii 500))
  (priority (string-ascii 20))
  (estimated-cost uint)
)
  (let
    (
      (property (unwrap! (map-get? maintenance-properties { property-id: property-id }) ERR-PROPERTY-NOT-FOUND))
      (work-order-id (var-get next-work-order-id))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> estimated-cost u0) ERR-INVALID-INPUT)

    (map-set work-orders
      { work-order-id: work-order-id }
      {
        property-id: property-id,
        violation-id: violation-id,
        work-type: work-type,
        description: description,
        priority: priority,
        assigned-contractor: none,
        estimated-cost: estimated-cost,
        status: "pending",
        created-date: block-height,
        completion-date: none
      }
    )

    (var-set next-work-order-id (+ work-order-id u1))
    (ok work-order-id)
  )
)

(define-public (assign-contractor (work-order-id uint) (contractor principal))
  (let
    (
      (work-order (unwrap! (map-get? work-orders { work-order-id: work-order-id }) ERR-VIOLATION-NOT-FOUND))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status work-order) "pending") ERR-INVALID-STATUS)

    (map-set work-orders
      { work-order-id: work-order-id }
      (merge work-order {
        assigned-contractor: (some contractor),
        status: "assigned"
      })
    )

    (ok true)
  )
)

(define-public (complete-work-order (work-order-id uint))
  (let
    (
      (work-order (unwrap! (map-get? work-orders { work-order-id: work-order-id }) ERR-VIOLATION-NOT-FOUND))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status work-order) "in-progress") ERR-INVALID-STATUS)

    (map-set work-orders
      { work-order-id: work-order-id }
      (merge work-order {
        status: "completed",
        completion-date: (some block-height)
      })
    )

    (ok true)
  )
)

;; Helper Functions
(define-private (calculate-fine (severity (string-ascii 20)))
  (if (is-eq severity "critical") u1000
    (if (is-eq severity "major") u500
      (if (is-eq severity "minor") u100 u50)
    )
  )
)

(define-private (get-correction-period (severity (string-ascii 20)))
  (if (is-eq severity "critical") u1440    ;; 1 day in blocks
    (if (is-eq severity "major") u10080    ;; 1 week in blocks
      (if (is-eq severity "minor") u43200  ;; 1 month in blocks
        u86400                             ;; 2 months in blocks
      )
    )
  )
)

;; Read-only Functions
(define-read-only (get-maintenance-property (property-id uint))
  (map-get? maintenance-properties { property-id: property-id })
)

(define-read-only (get-violation (violation-id uint))
  (map-get? code-violations { violation-id: violation-id })
)

(define-read-only (get-inspection (inspection-id uint))
  (map-get? inspections { inspection-id: inspection-id })
)

(define-read-only (get-work-order (work-order-id uint))
  (map-get? work-orders { work-order-id: work-order-id })
)

(define-read-only (get-maintenance-standard (standard-id (string-ascii 50)))
  (map-get? maintenance-standards { standard-id: standard-id })
)

(define-read-only (calculate-violation-fine (severity (string-ascii 20)))
  (calculate-fine severity)
)
