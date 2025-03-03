;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-rating (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-out-of-stock (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-invalid-inventory (err u106))
(define-constant err-not-purchaser (err u107))

;; Data variables
(define-data-var product-counter uint u0)

;; Data structures
(define-map products 
  uint 
  {
    name: (string-ascii 100),
    price: uint,
    inventory: uint,
    seller: principal,
    description: (string-ascii 500)
  }
)

(define-map reviews
  {product-id: uint, reviewer: principal}
  {
    rating: uint,
    comment: (string-ascii 240)
  }
)

(define-map seller-stats
  principal
  {
    total-sales: uint,
    total-ratings: uint,
    rating-sum: uint
  }
)

(define-map purchases
  {product-id: uint, buyer: principal}
  {purchased: bool}
)

;; Events
(define-data-var last-event-id uint u0)

(define-public (list-product (name (string-ascii 100)) (price uint) (inventory uint) (description (string-ascii 500)))
  (begin
    (asserts! (> price u0) err-invalid-price)
    (asserts! (> inventory u0) err-invalid-inventory)
    (var-set product-counter (+ (var-get product-counter) u1))
    (map-set products (var-get product-counter)
      {
        name: name,
        price: price,
        inventory: inventory,
        seller: tx-sender,
        description: description
      }
    )
    (print {event: "product-listed", product-id: (var-get product-counter), seller: tx-sender})
    (ok (var-get product-counter))
  )
)

(define-public (purchase-product (product-id uint) (seller principal))
  (let (
    (product (unwrap! (map-get? products product-id) err-not-found))
    (price (get price product))
    (current-inventory (get inventory product))
  )
    (asserts! (> current-inventory u0) err-out-of-stock)
    (try! (stx-transfer? price tx-sender seller))
    (map-set products product-id
      (merge product { inventory: (- current-inventory u1) })
    )
    (map-set purchases {product-id: product-id, buyer: tx-sender} {purchased: true})
    (try! (update-seller-stats seller u1))
    (print {event: "product-purchased", product-id: product-id, buyer: tx-sender})
    (ok true)
  )
)

(define-public (add-review (product-id uint) (rating uint) (comment (string-ascii 240)))
  (begin
    (asserts! (<= rating u5) err-invalid-rating)
    (asserts! (is-some (map-get? products product-id)) err-not-found)
    (asserts! (default-to false (get purchased (map-get? purchases {product-id: product-id, buyer: tx-sender}))) err-not-purchaser)
    (let ((product (unwrap-panic (map-get? products product-id))))
      (map-set reviews 
        {product-id: product-id, reviewer: tx-sender}
        {rating: rating, comment: comment}
      )
      (try! (update-seller-rating (get seller product) rating))
      (print {event: "review-added", product-id: product-id, reviewer: tx-sender})
      (ok true)
    )
  )
)

;; Helper functions
(define-private (update-seller-stats (seller principal) (sales uint))
  (let ((stats (default-to 
    {total-sales: u0, total-ratings: u0, rating-sum: u0}
    (map-get? seller-stats seller))))
    (map-set seller-stats seller
      (merge stats {total-sales: (+ (get total-sales stats) sales)})
    )
    (ok true)
  )
)

(define-private (update-seller-rating (seller principal) (rating uint))
  (let ((stats (default-to 
    {total-sales: u0, total-ratings: u0, rating-sum: u0}
    (map-get? seller-stats seller))))
    (map-set seller-stats seller
      (merge stats {
        total-ratings: (+ (get total-ratings stats) u1),
        rating-sum: (+ (get rating-sum stats) rating)
      })
    )
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-product (product-id uint))
  (ok (map-get? products product-id))
)

(define-read-only (get-seller-rating (seller principal))
  (let ((stats (default-to 
    {total-sales: u0, total-ratings: u0, rating-sum: u0}
    (map-get? seller-stats seller))))
    (ok {
      total-sales: (get total-sales stats),
      average-rating: (if (is-eq (get total-ratings stats) u0)
        u0
        (/ (get rating-sum stats) (get total-ratings stats)))
    })
  )
)

(define-read-only (get-last-product-id)
  (ok (var-get product-counter))
)
