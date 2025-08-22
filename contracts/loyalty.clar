;; Car Wash Loyalty Program Contract
;; Manages customer loyalty points, tiers, and rewards

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-POINTS (err u400))
(define-constant ERR-INVALID-POINTS (err u401))
(define-constant ERR-CUSTOMER-NOT-FOUND (err u402))

;; Tier thresholds
(define-constant BRONZE-THRESHOLD u0)
(define-constant SILVER-THRESHOLD u500)
(define-constant GOLD-THRESHOLD u1500)
(define-constant PLATINUM-THRESHOLD u3000)

;; Data Maps
(define-map customer-points principal {
  total-points: uint,
  available-points: uint,
  tier: (string-ascii 20),
  total-spent: uint,
  referrals: uint,
  created-at: uint
})

(define-map point-transactions uint {
  customer: principal,
  points: uint,
  transaction-type: (string-ascii 20),
  description: (string-ascii 100),
  timestamp: uint
})

(define-data-var next-transaction-id uint u1)

;; Private Functions
(define-private (calculate-tier (total-points uint))
  (if (>= total-points PLATINUM-THRESHOLD)
    "platinum"
    (if (>= total-points GOLD-THRESHOLD)
      "gold"
      (if (>= total-points SILVER-THRESHOLD)
        "silver"
        "bronze"))))

(define-private (get-tier-multiplier (tier (string-ascii 20)))
  (if (is-eq tier "platinum")
    u150
    (if (is-eq tier "gold")
      u125
      (if (is-eq tier "silver")
        u110
        u100))))

;; Public Functions

;; Add points to customer account
(define-public (add-points (customer principal) (points uint))
  (let ((current-data (default-to {
          total-points: u0,
          available-points: u0,
          tier: "bronze",
          total-spent: u0,
          referrals: u0,
          created-at: block-height
        } (map-get? customer-points customer)))
        (new-total (+ (get total-points current-data) points))
        (new-available (+ (get available-points current-data) points))
        (new-tier (calculate-tier new-total))
        (transaction-id (var-get next-transaction-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> points u0) ERR-INVALID-POINTS)
    (map-set customer-points customer
      (merge current-data {
        total-points: new-total,
        available-points: new-available,
        tier: new-tier
      }))
    (map-set point-transactions transaction-id {
      customer: customer,
      points: points,
      transaction-type: "earned",
      description: "Points earned from service",
      timestamp: block-height
    })
    (var-set next-transaction-id (+ transaction-id u1))
    (print {
      event: "points-added",
      customer: customer,
      points: points,
      new-total: new-total,
      new-tier: new-tier
    })
    (ok true)))

;; Redeem points for discount
(define-public (redeem-points (customer principal) (points uint))
  (let ((current-data (unwrap! (map-get? customer-points customer) ERR-CUSTOMER-NOT-FOUND))
        (transaction-id (var-get next-transaction-id)))
    (asserts! (>= (get available-points current-data) points) ERR-INSUFFICIENT-POINTS)
    (asserts! (> points u0) ERR-INVALID-POINTS)
    (map-set customer-points customer
      (merge current-data {
        available-points: (- (get available-points current-data) points)
      }))
    (map-set point-transactions transaction-id {
      customer: customer,
      points: points,
      transaction-type: "redeemed",
      description: "Points redeemed for discount",
      timestamp: block-height
    })
    (var-set next-transaction-id (+ transaction-id u1))
    (print {
      event: "points-redeemed",
      customer: customer,
      points: points,
      remaining: (- (get available-points current-data) points)
    })
    (ok true)))

;; Add referral bonus
(define-public (add-referral-bonus (referrer principal) (referred principal))
  (let ((referrer-data (default-to {
          total-points: u0,
          available-points: u0,
          tier: "bronze",
          total-spent: u0,
          referrals: u0,
          created-at: block-height
        } (map-get? customer-points referrer)))
        (bonus-points u100)
        (new-total (+ (get total-points referrer-data) bonus-points))
        (new-available (+ (get available-points referrer-data) bonus-points))
        (new-referrals (+ (get referrals referrer-data) u1))
        (transaction-id (var-get next-transaction-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set customer-points referrer
      (merge referrer-data {
        total-points: new-total,
        available-points: new-available,
        referrals: new-referrals,
        tier: (calculate-tier new-total)
      }))
    (map-set point-transactions transaction-id {
      customer: referrer,
      points: bonus-points,
      transaction-type: "referral",
      description: "Referral bonus points",
      timestamp: block-height
    })
    (var-set next-transaction-id (+ transaction-id u1))
    (print {
      event: "referral-bonus-added",
      referrer: referrer,
      referred: referred,
      bonus-points: bonus-points
    })
    (ok true)))

;; Read-only Functions

;; Get customer loyalty data
(define-read-only (get-customer-points (customer principal))
  (map-get? customer-points customer))

;; Get point transaction
(define-read-only (get-point-transaction (transaction-id uint))
  (map-get? point-transactions transaction-id))

;; Calculate discount percentage based on tier
(define-read-only (get-tier-discount (customer principal))
  (match (map-get? customer-points customer)
    customer-data
      (let ((tier (get tier customer-data)))
        (if (is-eq tier "platinum")
          u15
          (if (is-eq tier "gold")
            u10
            (if (is-eq tier "silver")
              u5
              u0))))
    u0))

;; Get next transaction ID
(define-read-only (get-next-transaction-id)
  (var-get next-transaction-id))
