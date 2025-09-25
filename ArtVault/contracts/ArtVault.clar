;; ArtVault - Decentralized Digital Art Gallery Platform Smart Contract
;; A platform for artists to exhibit digital art, connect with collectors, and monetize creations

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-already-exists (err u104))

;; Data Variables
(define-data-var next-piece-id uint u1)
(define-data-var gallery-fee uint u1000000) ;; 1 STX in microSTX

;; Data Maps
(define-map artist-profiles 
  { artist-wallet: principal }
  {
    artist-name: (string-ascii 50),
    biography: (string-utf8 500),
    reputation-score: uint,
    pieces-count: uint,
    collectors-count: uint,
    subscribed-count: uint,
    joined-at: uint,
    is-verified: bool
  }
)

(define-map gallery-pieces
  { piece-id: uint }
  {
    creator: principal,
    piece-description: (string-utf8 2000),
    favorites-count: uint,
    views-count: uint,
    exhibited-at: uint,
    commission-total: uint,
    is-highlighted: bool
  }
)

(define-map artist-connections
  { collector: principal, artist: principal }
  { subscribed-at: uint }
)

(define-map piece-favorites
  { piece-id: uint, collector: principal }
  { favorited-at: uint }
)

(define-map piece-commissions
  { piece-id: uint, sponsor: principal }
  { commission-amount: uint, paid-at: uint }
)

(define-map artist-metrics
  { artist-wallet: principal }
  {
    total-commissions-received: uint,
    total-commissions-paid: uint,
    stx-wallet-balance: uint,
    gallery-membership-duration: uint
  }
)

;; Helper Functions
(define-private (is-valid-artist-name (artist-name (string-ascii 50)))
  (and 
    (> (len artist-name) u2)
    (< (len artist-name) u51)
  )
)

(define-private (calculate-reputation-score (artist principal))
  (let (
    (artist-data (unwrap! (map-get? artist-profiles { artist-wallet: artist }) u0))
    (metrics (default-to 
      { total-commissions-received: u0, total-commissions-paid: u0, stx-wallet-balance: u0, gallery-membership-duration: u0 }
      (map-get? artist-metrics { artist-wallet: artist })
    ))
  )
  (+
    ;; Base score from pieces and artistic activity
    (* (get pieces-count artist-data) u10)
    (* (get collectors-count artist-data) u5)
    ;; Commissions received adds to reputation
    (/ (get total-commissions-received metrics) u1000000)
    ;; STX balance contributes to reputation
    (/ (get stx-wallet-balance metrics) u10000000)
    ;; Gallery membership bonus
    (/ (get gallery-membership-duration metrics) u1000)
  ))
)

;; Public Functions

;; Join ArtVault
(define-public (register-artist (artist-name (string-ascii 50)) (biography (string-utf8 500)))
  (let (
    (current-block burn-block-height)
  )
    (asserts! (is-valid-artist-name artist-name) err-invalid-input)
    (asserts! (is-none (map-get? artist-profiles { artist-wallet: tx-sender })) err-already-exists)
    
    (map-set artist-profiles 
      { artist-wallet: tx-sender }
      {
        artist-name: artist-name,
        biography: biography,
        reputation-score: u0,
        pieces-count: u0,
        collectors-count: u0,
        subscribed-count: u0,
        joined-at: current-block,
        is-verified: false
      }
    )
    
    (map-set artist-metrics
      { artist-wallet: tx-sender }
      {
        total-commissions-received: u0,
        total-commissions-paid: u0,
        stx-wallet-balance: (stx-get-balance tx-sender),
        gallery-membership-duration: u0
      }
    )
    
    (ok true)
  )
)

;; Exhibit a new art piece
(define-public (exhibit-piece (piece-description (string-utf8 2000)))
  (let (
    (piece-id (var-get next-piece-id))
    (current-block burn-block-height)
    (artist-data (unwrap! (map-get? artist-profiles { artist-wallet: tx-sender }) err-not-found))
  )
    (asserts! (> (len piece-description) u0) err-invalid-input)
    (asserts! (<= (len piece-description) u2000) err-invalid-input)
    
    ;; Create the art piece
    (map-set gallery-pieces
      { piece-id: piece-id }
      {
        creator: tx-sender,
        piece-description: piece-description,
        favorites-count: u0,
        views-count: u0,
        exhibited-at: current-block,
        commission-total: u0,
        is-highlighted: false
      }
    )
    
    ;; Update artist piece count
    (map-set artist-profiles
      { artist-wallet: tx-sender }
      (merge artist-data { pieces-count: (+ (get pieces-count artist-data) u1) })
    )
    
    ;; Increment piece ID counter
    (var-set next-piece-id (+ piece-id u1))
    
    ;; Update reputation score
    (try! (update-reputation-score tx-sender))
    
    (ok piece-id)
  )
)

;; Subscribe to another artist
(define-public (subscribe-to-artist (artist-to-subscribe principal))
  (let (
    (collector-data (unwrap! (map-get? artist-profiles { artist-wallet: tx-sender }) err-not-found))
    (artist-data (unwrap! (map-get? artist-profiles { artist-wallet: artist-to-subscribe }) err-not-found))
    (current-block burn-block-height)
  )
    (asserts! (not (is-eq tx-sender artist-to-subscribe)) err-invalid-input)
    (asserts! (is-none (map-get? artist-connections { collector: tx-sender, artist: artist-to-subscribe })) err-already-exists)
    
    ;; Create subscription relationship
    (map-set artist-connections
      { collector: tx-sender, artist: artist-to-subscribe }
      { subscribed-at: current-block }
    )
    
    ;; Update collector's subscribed count
    (map-set artist-profiles
      { artist-wallet: tx-sender }
      (merge collector-data { subscribed-count: (+ (get subscribed-count collector-data) u1) })
    )
    
    ;; Update artist's collectors count
    (map-set artist-profiles
      { artist-wallet: artist-to-subscribe }
      (merge artist-data { collectors-count: (+ (get collectors-count artist-data) u1) })
    )
    
    ;; Update reputation scores
    (try! (update-reputation-score tx-sender))
    (try! (update-reputation-score artist-to-subscribe))
    
    (ok true)
  )
)

;; Favorite an art piece
(define-public (favorite-piece (piece-id uint))
  (let (
    (piece-data (unwrap! (map-get? gallery-pieces { piece-id: piece-id }) err-not-found))
    (current-block burn-block-height)
  )
    (asserts! (is-some (map-get? artist-profiles { artist-wallet: tx-sender })) err-unauthorized)
    (asserts! (is-none (map-get? piece-favorites { piece-id: piece-id, collector: tx-sender })) err-already-exists)
    
    ;; Create favorite record
    (map-set piece-favorites
      { piece-id: piece-id, collector: tx-sender }
      { favorited-at: current-block }
    )
    
    ;; Update piece favorites count
    (map-set gallery-pieces
      { piece-id: piece-id }
      (merge piece-data { favorites-count: (+ (get favorites-count piece-data) u1) })
    )
    
    ;; Update artist's reputation
    (try! (update-reputation-score (get creator piece-data)))
    
    (ok true)
  )
)

;; Commission artist through piece support
(define-public (commission-piece (piece-id uint) (commission-amount uint))
  (let (
    (piece-data (unwrap! (map-get? gallery-pieces { piece-id: piece-id }) err-not-found))
    (creator (get creator piece-data))
    (current-block burn-block-height)
    (sponsor-metrics (default-to 
      { total-commissions-received: u0, total-commissions-paid: u0, stx-wallet-balance: u0, gallery-membership-duration: u0 }
      (map-get? artist-metrics { artist-wallet: tx-sender })
    ))
    (creator-metrics (default-to 
      { total-commissions-received: u0, total-commissions-paid: u0, stx-wallet-balance: u0, gallery-membership-duration: u0 }
      (map-get? artist-metrics { artist-wallet: creator })
    ))
  )
    (asserts! (> commission-amount u0) err-invalid-input)
    (asserts! (not (is-eq tx-sender creator)) err-invalid-input)
    
    ;; Transfer STX to creator
    (try! (stx-transfer? commission-amount tx-sender creator))
    
    ;; Record the commission transfer
    (map-set piece-commissions
      { piece-id: piece-id, sponsor: tx-sender }
      { commission-amount: commission-amount, paid-at: current-block }
    )
    
    ;; Update piece commission total
    (map-set gallery-pieces
      { piece-id: piece-id }
      (merge piece-data { commission-total: (+ (get commission-total piece-data) commission-amount) })
    )
    
    ;; Update sponsor metrics
    (map-set artist-metrics
      { artist-wallet: tx-sender }
      (merge sponsor-metrics { total-commissions-paid: (+ (get total-commissions-paid sponsor-metrics) commission-amount) })
    )
    
    ;; Update creator metrics
    (map-set artist-metrics
      { artist-wallet: creator }
      (merge creator-metrics { total-commissions-received: (+ (get total-commissions-received creator-metrics) commission-amount) })
    )
    
    ;; Update reputation scores
    (try! (update-reputation-score tx-sender))
    (try! (update-reputation-score creator))
    
    (ok true)
  )
)

;; Update artist reputation score
(define-private (update-reputation-score (artist principal))
  (let (
    (artist-data (unwrap! (map-get? artist-profiles { artist-wallet: artist }) (err u0)))
    (new-score (calculate-reputation-score artist))
  )
    (map-set artist-profiles
      { artist-wallet: artist }
      (merge artist-data { reputation-score: new-score })
    )
    (ok new-score)
  )
)

;; Read-only functions

;; Get artist profile
(define-read-only (get-artist-profile (artist principal))
  (map-get? artist-profiles { artist-wallet: artist })
)

;; Get art piece details
(define-read-only (get-piece (piece-id uint))
  (map-get? gallery-pieces { piece-id: piece-id })
)

;; Check if user subscribes to an artist
(define-read-only (is-subscribed (collector principal) (artist principal))
  (is-some (map-get? artist-connections { collector: collector, artist: artist }))
)

;; Get artist metrics
(define-read-only (get-artist-metrics (artist principal))
  (map-get? artist-metrics { artist-wallet: artist })
)

;; Check if user favorited a piece
(define-read-only (has-favorited-piece (piece-id uint) (collector principal))
  (is-some (map-get? piece-favorites { piece-id: piece-id, collector: collector }))
)

;; Get current piece ID counter
(define-read-only (get-next-piece-id)
  (var-get next-piece-id))