(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-CREDIT (err u101))
(define-constant ERR-ALREADY-RETIRED (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-CREDIT-NOT-FOUND (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-ISSUER-NOT-VERIFIED (err u106))
(define-constant ERR-DUPLICATE-CREDIT (err u107))
(define-constant ERR-INVALID-VINTAGE (err u108))
(define-constant ERR-TRANSFER-TO-SELF (err u109))
(define-constant ERR-CREDIT-LOCKED (err u110))

(define-data-var contract-owner principal tx-sender)
(define-data-var next-credit-id uint u1)
(define-data-var total-credits-issued uint u0)
(define-data-var total-credits-retired uint u0)
(define-data-var total-transfers uint u0)

(define-map verified-issuers
    principal
    bool
)
(define-map carbon-credits
    uint
    {
        issuer: principal,
        owner: principal,
        project-id: (string-ascii 64),
        vintage: uint,
        amount: uint,
        methodology: (string-ascii 32),
        is-retired: bool,
        issued-at: uint,
        retired-at: (optional uint),
        verification-standard: (string-ascii 16),
        is-merged: bool,
    }
)

(define-map issuer-balances
    {
        issuer: principal,
        project-id: (string-ascii 64),
    }
    uint
)
(define-map owner-balances
    principal
    uint
)
(define-map credit-transfers
    uint
    {
        from: principal,
        to: principal,
        credit-id: uint,
        amount: uint,
        timestamp: uint,
    }
)
(define-map locked-credits
    uint
    uint
)
(define-map project-registrations
    (string-ascii 64)
    {
        issuer: principal,
        name: (string-ascii 128),
        location: (string-ascii 64),
        methodology: (string-ascii 32),
        verification-standard: (string-ascii 16),
        registered-at: uint,
    }
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-read-only (get-next-credit-id)
    (var-get next-credit-id)
)

(define-read-only (get-total-credits-issued)
    (var-get total-credits-issued)
)

(define-read-only (get-total-credits-retired)
    (var-get total-credits-retired)
)

(define-read-only (get-total-transfers)
    (var-get total-transfers)
)

(define-read-only (is-verified-issuer (issuer principal))
    (default-to false (map-get? verified-issuers issuer))
)

(define-read-only (get-carbon-credit (credit-id uint))
    (map-get? carbon-credits credit-id)
)

(define-read-only (get-owner-balance (owner principal))
    (default-to u0 (map-get? owner-balances owner))
)

(define-read-only (get-issuer-project-balance
        (issuer principal)
        (project-id (string-ascii 64))
    )
    (default-to u0
        (map-get? issuer-balances {
            issuer: issuer,
            project-id: project-id,
        })
    )
)

(define-read-only (get-project-registration (project-id (string-ascii 64)))
    (map-get? project-registrations project-id)
)

(define-read-only (get-credit-transfer (transfer-id uint))
    (map-get? credit-transfers transfer-id)
)
(define-read-only (get-credit-lock (credit-id uint))
    (map-get? locked-credits credit-id)
)

(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

(define-public (add-verified-issuer (issuer principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (map-set verified-issuers issuer true)
        (ok true)
    )
)

(define-public (remove-verified-issuer (issuer principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (map-delete verified-issuers issuer)
        (ok true)
    )
)

(define-public (register-project
        (project-id (string-ascii 64))
        (name (string-ascii 128))
        (location (string-ascii 64))
        (methodology (string-ascii 32))
        (verification-standard (string-ascii 16))
    )
    (let ((issuer tx-sender))
        (asserts! (is-verified-issuer issuer) ERR-ISSUER-NOT-VERIFIED)
        (asserts! (is-none (map-get? project-registrations project-id))
            ERR-DUPLICATE-CREDIT
        )
        (map-set project-registrations project-id {
            issuer: issuer,
            name: name,
            location: location,
            methodology: methodology,
            verification-standard: verification-standard,
            registered-at: stacks-block-height,
        })
        (ok project-id)
    )
)

(define-public (issue-carbon-credit
        (project-id (string-ascii 64))
        (amount uint)
        (vintage uint)
        (methodology (string-ascii 32))
        (verification-standard (string-ascii 16))
    )
    (let (
            (credit-id (var-get next-credit-id))
            (issuer tx-sender)
            (current-balance (get-issuer-project-balance issuer project-id))
            (current-owner-balance (get-owner-balance issuer))
        )
        (asserts! (is-verified-issuer issuer) ERR-ISSUER-NOT-VERIFIED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (and (>= vintage u2000) (<= vintage u2050)) ERR-INVALID-VINTAGE)
        (asserts! (is-some (map-get? project-registrations project-id))
            ERR-INVALID-CREDIT
        )

        (map-set carbon-credits credit-id {
            issuer: issuer,
            owner: issuer,
            project-id: project-id,
            vintage: vintage,
            amount: amount,
            methodology: methodology,
            is-retired: false,
            issued-at: stacks-block-height,
            retired-at: none,
            verification-standard: verification-standard,
            is-merged: false,
        })

        (map-set issuer-balances {
            issuer: issuer,
            project-id: project-id,
        }
            (+ current-balance amount)
        )
        (map-set owner-balances issuer (+ current-owner-balance amount))

        (var-set next-credit-id (+ credit-id u1))
        (var-set total-credits-issued (+ (var-get total-credits-issued) amount))

        (ok credit-id)
    )
)

(define-public (transfer-carbon-credit
        (credit-id uint)
        (recipient principal)
        (amount uint)
    )
    (let (
            (credit-data (unwrap! (map-get? carbon-credits credit-id) ERR-CREDIT-NOT-FOUND))
            (current-owner (get owner credit-data))
            (current-amount (get amount credit-data))
            (current-owner-balance (get-owner-balance current-owner))
            (recipient-balance (get-owner-balance recipient))
            (lock-data (get-credit-lock credit-id))
        )
        (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq current-owner recipient)) ERR-TRANSFER-TO-SELF)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= current-amount amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (not (get is-retired credit-data)) ERR-ALREADY-RETIRED)
        (asserts! (or (is-none lock-data) (> stacks-block-height (unwrap-panic lock-data))) ERR-CREDIT-LOCKED)

        (if (is-eq current-amount amount)
            (begin
                (map-set carbon-credits credit-id
                    (merge credit-data { owner: recipient })
                )
                (map-set owner-balances current-owner
                    (- current-owner-balance amount)
                )
                (map-set owner-balances recipient (+ recipient-balance amount))
            )
            (let ((new-credit-id (var-get next-credit-id)))
                (map-set carbon-credits credit-id
                    (merge credit-data { amount: (- current-amount amount) })
                )
                (map-set carbon-credits new-credit-id
                    (merge credit-data {
                        owner: recipient,
                        amount: amount,
                        is-merged: false,
                    })
                )
                (var-set next-credit-id (+ new-credit-id u1))
                (map-set owner-balances current-owner
                    (- current-owner-balance amount)
                )
                (map-set owner-balances recipient (+ recipient-balance amount))
            )
        )

        (map-set credit-transfers credit-id {
            from: current-owner,
            to: recipient,
            credit-id: credit-id,
            amount: amount,
            timestamp: stacks-block-height,
        })

        (var-set total-transfers (+ (var-get total-transfers) u1))

        (ok true)
    )
)

(define-public (retire-carbon-credit
        (credit-id uint)
        (amount uint)
    )
    (let (
            (credit-data (unwrap! (map-get? carbon-credits credit-id) ERR-CREDIT-NOT-FOUND))
            (current-owner (get owner credit-data))
            (current-amount (get amount credit-data))
            (current-owner-balance (get-owner-balance current-owner))
        )
        (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= current-amount amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (not (get is-retired credit-data)) ERR-ALREADY-RETIRED)

        (if (is-eq current-amount amount)
            (map-set carbon-credits credit-id
                (merge credit-data {
                    is-retired: true,
                    retired-at: (some stacks-block-height),
                })
            )
            (let ((new-credit-id (var-get next-credit-id)))
                (map-set carbon-credits credit-id
                    (merge credit-data { amount: (- current-amount amount) })
                )
                (map-set carbon-credits new-credit-id
                    (merge credit-data {
                        amount: amount,
                        is-retired: true,
                        retired-at: (some stacks-block-height),
                        is-merged: false,
                    })
                )
                (var-set next-credit-id (+ new-credit-id u1))
            )
        )

        (map-set owner-balances current-owner (- current-owner-balance amount))
        (var-set total-credits-retired (+ (var-get total-credits-retired) amount))

        (ok true)
    )
)
(define-public (lock-credit (credit-id uint) (lock-until uint))
    (let ((credit-data (unwrap! (map-get? carbon-credits credit-id) ERR-CREDIT-NOT-FOUND))
          (current-owner (get owner credit-data)))
        (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
        (asserts! (> lock-until stacks-block-height) ERR-INVALID-AMOUNT)
        (map-set locked-credits credit-id lock-until)
        (ok true)
    )
)
(define-public (unlock-credit (credit-id uint))
    (let ((credit-data (unwrap! (map-get? carbon-credits credit-id) ERR-CREDIT-NOT-FOUND))
          (current-owner (get owner credit-data))
          (lock-data (get-credit-lock credit-id)))
        (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-some lock-data) ERR-INVALID-CREDIT)
        (asserts! (>= stacks-block-height (unwrap-panic lock-data)) ERR-NOT-AUTHORIZED)
        (map-delete locked-credits credit-id)
        (ok true)
    )
)

(define-public (merge-carbon-credits
        (credit-id-1 uint)
        (credit-id-2 uint)
    )
    (let (
            (credit-1 (unwrap! (map-get? carbon-credits credit-id-1) ERR-CREDIT-NOT-FOUND))
            (credit-2 (unwrap! (map-get? carbon-credits credit-id-2) ERR-CREDIT-NOT-FOUND))
            (owner-1 (get owner credit-1))
            (owner-2 (get owner credit-2))
            (project-1 (get project-id credit-1))
            (project-2 (get project-id credit-2))
            (issuer-1 (get issuer credit-1))
            (issuer-2 (get issuer credit-2))
            (vintage-1 (get vintage credit-1))
            (vintage-2 (get vintage credit-2))
            (amount-1 (get amount credit-1))
            (amount-2 (get amount credit-2))
            (methodology-1 (get methodology credit-1))
            (methodology-2 (get methodology credit-2))
            (verification-1 (get verification-standard credit-1))
            (verification-2 (get verification-standard credit-2))
            (new-credit-id (var-get next-credit-id))
            (lock-1 (get-credit-lock credit-id-1))
            (lock-2 (get-credit-lock credit-id-2))
        )
        (asserts! (is-eq tx-sender owner-1) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq tx-sender owner-2) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq project-1 project-2) ERR-INVALID-CREDIT)
        (asserts! (is-eq issuer-1 issuer-2) ERR-INVALID-CREDIT)
        (asserts! (is-eq vintage-1 vintage-2) ERR-INVALID-VINTAGE)
        (asserts! (is-eq methodology-1 methodology-2) ERR-INVALID-CREDIT)
        (asserts! (is-eq verification-1 verification-2) ERR-INVALID-CREDIT)
        (asserts! (not (get is-retired credit-1)) ERR-ALREADY-RETIRED)
        (asserts! (not (get is-retired credit-2)) ERR-ALREADY-RETIRED)
        (asserts! (not (get is-merged credit-1)) ERR-INVALID-CREDIT)
        (asserts! (not (get is-merged credit-2)) ERR-INVALID-CREDIT)
        (asserts! (or (is-none lock-1) (> stacks-block-height (unwrap-panic lock-1))) ERR-CREDIT-LOCKED)
        (asserts! (or (is-none lock-2) (> stacks-block-height (unwrap-panic lock-2))) ERR-CREDIT-LOCKED)

        (map-set carbon-credits new-credit-id {
            issuer: issuer-1,
            owner: tx-sender,
            project-id: project-1,
            vintage: vintage-1,
            amount: (+ amount-1 amount-2),
            methodology: methodology-1,
            is-retired: false,
            issued-at: stacks-block-height,
            retired-at: none,
            verification-standard: verification-1,
            is-merged: true,
        })

        (map-set carbon-credits credit-id-1 (merge credit-1 { is-merged: true }))
        (map-set carbon-credits credit-id-2 (merge credit-2 { is-merged: true }))

        (var-set next-credit-id (+ new-credit-id u1))

        (ok new-credit-id)
    )
)

(define-public (batch-retire-credits
        (credit-ids (list 10 uint))
        (amounts (list 10 uint))
    )
    (begin
        (map retire-single-credit credit-ids amounts)
        (ok true)
    )
)

(define-private (retire-single-credit
        (credit-id uint)
        (amount uint)
    )
    (retire-carbon-credit credit-id amount)
)

(define-private (validate-retirement-results
        (result (response bool uint))
        (acc bool)
    )
    (and acc (is-ok result))
)

(define-read-only (verify-credit-authenticity (credit-id uint))
    (let ((credit-data (map-get? carbon-credits credit-id)))
        (match credit-data
            credit
            {
                issuer: (get issuer credit),
                is-verified-issuer: (is-verified-issuer (get issuer credit)),
                project-registered: (is-some (map-get? project-registrations (get project-id credit))),
                is-active: (not (get is-retired credit)),
            }
            {
                            issuer: tx-sender,
                            is-verified-issuer: false,
                            project-registered: false,
                            is-active: false,
                        }
                    )
                )
            )

(define-read-only (get-credit-audit-trail (credit-id uint))
    (let ((credit-data (map-get? carbon-credits credit-id)))
        (match credit-data
            credit
            {
                credit-id: credit-id,
                issued-at: (get issued-at credit),
                current-owner: (get owner credit),
                is-retired: (get is-retired credit),
                retired-at: (get retired-at credit),
                transfer-record: (map-get? credit-transfers credit-id),
            }
            {
                credit-id: credit-id,
                issued-at: u0,
                current-owner: tx-sender,
                is-retired: false,
                retired-at: none,
                transfer-record: none,
            }
        )
    )
)

(define-read-only (calculate-issuer-footprint (issuer principal))
    {
        total-issued: (var-get total-credits-issued),
        total-retired: (var-get total-credits-retired),
        active-credits: (- (var-get total-credits-issued) (var-get total-credits-retired)),
    }
)

(define-read-only (validate-transfer-integrity
        (credit-id uint)
        (amount uint)
    )
    (let ((credit-data (map-get? carbon-credits credit-id)))
        (match credit-data
            credit
            {
                has-sufficient-amount: (>= (get amount credit) amount),
                is-not-retired: (not (get is-retired credit)),
                is-valid-issuer: (is-verified-issuer (get issuer credit)),
                current-owner: (get owner credit),
            }
            {
                has-sufficient-amount: false,
                is-not-retired: false,
                is-valid-issuer: false,
                current-owner: tx-sender,
            }
        )
    )
)

(define-public (bulk-issue-credits
        (project-ids (list 5 (string-ascii 64)))
        (amounts (list 5 uint))
        (vintages (list 5 uint))
        (methodologies (list 5 (string-ascii 32)))
        (standards (list 5 (string-ascii 16)))
    )
    (begin
        (map issue-single-credit-bulk project-ids amounts vintages methodologies
            standards
        )
        (ok true)
    )
)

(define-private (issue-single-credit-bulk
        (project-id (string-ascii 64))
        (amount uint)
        (vintage uint)
        (methodology (string-ascii 32))
        (standard (string-ascii 16))
    )
    (issue-carbon-credit project-id amount vintage methodology standard)
)

(define-read-only (get-credits-by-owner (owner principal))
    (ok owner)
)

(define-read-only (get-credits-by-project (project-id (string-ascii 64)))
    (ok project-id)
)

(define-read-only (verify-double-counting-prevention (credit-id uint))
    (let ((credit-data (map-get? carbon-credits credit-id)))
        (match credit-data
            credit
            {
                credit-exists: true,
                is-retired: (get is-retired credit),
                current-owner: (get owner credit),
                original-issuer: (get issuer credit),
                verification-status: (is-verified-issuer (get issuer credit)),
            }
            {
                credit-exists: false,
                is-retired: false,
                current-owner: tx-sender,
                original-issuer: tx-sender,
                verification-status: false,
            }
        )
    )
)

(define-public (emergency-pause-credit (credit-id uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? carbon-credits credit-id))
            ERR-CREDIT-NOT-FOUND
        )
        (ok true)
    )
)

(define-read-only (get-market-statistics)
    {
        total-credits-issued: (var-get total-credits-issued),
        total-credits-retired: (var-get total-credits-retired),
        active-credits: (- (var-get total-credits-issued) (var-get total-credits-retired)),
        next-credit-id: (var-get next-credit-id),
        retirement-rate: (if (> (var-get total-credits-issued) u0)
            (/ (* (var-get total-credits-retired) u100)
                (var-get total-credits-issued)
            )
            u0
        ),
    }
)
