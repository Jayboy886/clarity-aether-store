;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-rating (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-out-of-stock (err u104))

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

;; Product listing
(define-public (list-product (name (string-ascii 100)) (price uint) (inventory uint) (description (string-ascii 500)))
  (let ((product-id (+ u1 (default-to u0 (get-last-product-id)))))
    (map-set products product-id
      {
        name: name,
        price: price,
        inventory: inventory,
        seller: tx-sender,
        description: description
      }
    )
    (ok product-id)
  )
)

;; Purchase product
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
    (update-seller-stats seller u1)
    (ok true)
  )
)

;; Review system
(define-public (add-review (product-id uint) (rating uint) (comment (string-ascii 240)))
  (begin
    (asserts! (<= rating u5) err-invalid-rating)
    (asserts! (is-some (map-get? products product-id)) err-not-found)
    (let ((product (unwrap-panic (map-get? products product-id))))
      (map-set reviews 
        {product-id: product-id, reviewer: tx-sender}
        {rating: rating, comment: comment}
      )
      (update-seller-rating (get seller product) rating)
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
  (ok (default-to u0 (map-get? products u0)))
)
