;; Car Wash Fleet Services Contract
;; Manages commercial accounts and fleet service coordination

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FLEET-NOT-FOUND (err u600))
(define-constant ERR-INVALID-DISCOUNT (err u601))
(define-constant ERR-INSUFFICIENT-CREDITS (err u602))
(define-constant ERR-PACKAGE-NOT-FOUND (err u603))

;; Data Variables
(define-data-var next-fleet-id uint u1)
(define-data-var next-package-id uint u1)

;; Data Maps
(define-map fleet-accounts uint {
  company-name: (string-ascii 100),
  contact-person: (string-ascii 50),
  email: (string-ascii 100),
  phone: (string-ascii 20),
  vehicle-count: uint,
  discount-rate: uint,
  credit-balance: uint,
  total-spent: uint,
  created-at: uint,
  active: bool
})

(define-map fleet-packages uint {
  package-name: (string-ascii 50),
  services-included: (list 10 uint),
  package-price: uint,
  vehicle-limit: uint,
  validity-days: uint,
  active: bool,
  created-at: uint
})

(define-map fleet-subscriptions uint {
  fleet-id: uint,
  package-id: uint,
  start-date: uint,
  end-date: uint,
  services-used: uint,
  services-remaining: uint,
  auto-renew: bool
})

(define-map bulk-appointments uint {
  fleet-id: uint,
  appointment-date: uint,
  vehicle-count: uint,
  service-location: (string-ascii 200),
  special-instructions: (string-ascii 500),
  status: (string-ascii 20),
  created-at: uint
})

(define-data-var next-subscription-id uint u1)
(define-data-var next-bulk-appointment-id uint u1)

;; Private Functions
(define-private (is-valid-discount (discount uint))
  (and (>= discount u0) (<= discount u50)))

(define-private (calculate-fleet-price (base-price uint) (discount-rate uint))
  (- base-price (/ (* base-price discount-rate) u100)))

;; Public Functions

;; Register new fleet account
(define-public (register-fleet-account
  (company-name (string-ascii 100))
  (contact-person (string-ascii 50))
  (email (string-ascii 100))
  (phone (string-ascii 20))
  (vehicle-count uint)
  (discount-rate uint))
  (let ((fleet-id (var-get next-fleet-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-discount discount-rate) ERR-INVALID-DISCOUNT)
    (map-set fleet-accounts fleet-id {
      company-name: company-name,
      contact-person: contact-person,
      email: email,
      phone: phone,
      vehicle-count: vehicle-count,
      discount-rate: discount-rate,
      credit-balance: u0,
      total-spent: u0,
      created-at: block-height,
      active: true
    })
    (var-set next-fleet-id (+ fleet-id u1))
    (print {
      event: "fleet-account-registered",
      fleet-id: fleet-id,
      company-name: company-name,
      discount-rate: discount-rate
    })
    (ok fleet-id)))

;; Create fleet service package
(define-public (create-fleet-package
  (package-name (string-ascii 50))
  (services-included (list 10 uint))
  (package-price uint)
  (vehicle-limit uint)
  (validity-days uint))
  (let ((package-id (var-get next-package-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set fleet-packages package-id {
      package-name: package-name,
      services-included: services-included,
      package-price: package-price,
      vehicle-limit: vehicle-limit,
      validity-days: validity-days,
      active: true,
      created-at: block-height
    })
    (var-set next-package-id (+ package-id u1))
    (print {
      event: "fleet-package-created",
      package-id: package-id,
      package-name: package-name,
      package-price: package-price
    })
    (ok package-id)))

;; Add credits to fleet account
(define-public (add-fleet-credits (fleet-id uint) (credits uint))
  (let ((fleet (unwrap! (map-get? fleet-accounts fleet-id) ERR-FLEET-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set fleet-accounts fleet-id
      (merge fleet {
        credit-balance: (+ (get credit-balance fleet) credits)
      }))
    (print {
      event: "fleet-credits-added",
      fleet-id: fleet-id,
      credits: credits,
      new-balance: (+ (get credit-balance fleet) credits)
    })
    (ok true)))

;; Schedule bulk appointment
(define-public (schedule-bulk-appointment
  (fleet-id uint)
  (appointment-date uint)
  (vehicle-count uint)
  (service-location (string-ascii 200))
  (special-instructions (string-ascii 500)))
  (let ((fleet (unwrap! (map-get? fleet-accounts fleet-id) ERR-FLEET-NOT-FOUND))
        (bulk-id (var-get next-bulk-appointment-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (get active fleet) (err u604))
    (map-set bulk-appointments bulk-id {
      fleet-id: fleet-id,
      appointment-date: appointment-date,
      vehicle-count: vehicle-count,
      service-location: service-location,
      special-instructions: special-instructions,
      status: "scheduled",
      created-at: block-height
    })
    (var-set next-bulk-appointment-id (+ bulk-id u1))
    (print {
      event: "bulk-appointment-scheduled",
      bulk-id: bulk-id,
      fleet-id: fleet-id,
      vehicle-count: vehicle-count,
      appointment-date: appointment-date
    })
    (ok bulk-id)))

;; Subscribe fleet to package
(define-public (subscribe-fleet-to-package
  (fleet-id uint)
  (package-id uint)
  (auto-renew bool))
  (let ((fleet (unwrap! (map-get? fleet-accounts fleet-id) ERR-FLEET-NOT-FOUND))
        (package (unwrap! (map-get? fleet-packages package-id) ERR-PACKAGE-NOT-FOUND))
        (subscription-id (var-get next-subscription-id))
        (discounted-price (calculate-fleet-price (get package-price package) (get discount-rate fleet))))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= (get credit-balance fleet) discounted-price) ERR-INSUFFICIENT-CREDITS)
    (map-set fleet-subscriptions subscription-id {
      fleet-id: fleet-id,
      package-id: package-id,
      start-date: block-height,
      end-date: (+ block-height (get validity-days package)),
      services-used: u0,
      services-remaining: (get vehicle-limit package),
      auto-renew: auto-renew
    })
    (map-set fleet-accounts fleet-id
      (merge fleet {
        credit-balance: (- (get credit-balance fleet) discounted-price),
        total-spent: (+ (get total-spent fleet) discounted-price)
      }))
    (var-set next-subscription-id (+ subscription-id u1))
    (print {
      event: "fleet-subscribed-to-package",
      subscription-id: subscription-id,
      fleet-id: fleet-id,
      package-id: package-id,
      price-paid: discounted-price
    })
    (ok subscription-id)))

;; Read-only Functions

;; Get fleet account details
(define-read-only (get-fleet-account (fleet-id uint))
  (map-get? fleet-accounts fleet-id))

;; Get fleet package details
(define-read-only (get-fleet-package (package-id uint))
  (map-get? fleet-packages package-id))

;; Get fleet subscription details
(define-read-only (get-fleet-subscription (subscription-id uint))
  (map-get? fleet-subscriptions subscription-id))

;; Get bulk appointment details
(define-read-only (get-bulk-appointment (bulk-id uint))
  (map-get? bulk-appointments bulk-id))

;; Calculate discounted price for fleet
(define-read-only (calculate-discounted-price (fleet-id uint) (base-price uint))
  (match (map-get? fleet-accounts fleet-id)
    fleet (ok (calculate-fleet-price base-price (get discount-rate fleet)))
    ERR-FLEET-NOT-FOUND))

;; Get next fleet ID
(define-read-only (get-next-fleet-id)
  (var-get next-fleet-id))

;; Get next package ID
(define-read-only (get-next-package-id)
  (var-get next-package-id))
