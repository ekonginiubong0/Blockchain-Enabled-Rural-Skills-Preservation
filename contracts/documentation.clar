;; Documentation Contract
;; Records techniques through text, photos, and video

;; Data Variables
(define-data-var document-counter uint u0)

;; Data Maps
(define-map documents
  { document-id: uint }
  {
    creator: principal,
    skill-id: uint,
    title: (string-utf8 100),
    description: (string-utf8 500),
    content-type: (string-utf8 20),
    content-hash: (buff 32),
    verified: bool,
    timestamp: uint
  }
)

(define-map skill-documents
  { skill-id: uint }
  { document-ids: (list 100 uint) }
)

(define-map practitioner-documents
  { practitioner-id: principal }
  { document-ids: (list 100 uint) }
)

;; Add a new document for a skill
(define-public (add-document
    (skill-id uint)
    (title (string-utf8 100))
    (description (string-utf8 500))
    (content-type (string-utf8 20))
    (content-hash (buff 32)))
  (let ((document-id (var-get document-counter)))
    (begin
      ;; Store the document
      (map-set documents
        { document-id: document-id }
        {
          creator: tx-sender,
          skill-id: skill-id,
          title: title,
          description: description,
          content-type: content-type,
          content-hash: content-hash,
          verified: false,
          timestamp: block-height
        }
      )

      ;; Update skill's document list
      (let ((current-skill-docs (default-to { document-ids: (list) } (map-get? skill-documents { skill-id: skill-id }))))
        (map-set skill-documents
          { skill-id: skill-id }
          { document-ids: (unwrap-panic (as-max-len? (append (get document-ids current-skill-docs) document-id) u100)) }
        )
      )

      ;; Update practitioner's document list
      (let ((current-practitioner-docs (default-to { document-ids: (list) } (map-get? practitioner-documents { practitioner-id: tx-sender }))))
        (map-set practitioner-documents
          { practitioner-id: tx-sender }
          { document-ids: (unwrap-panic (as-max-len? (append (get document-ids current-practitioner-docs) document-id) u100)) }
        )
      )

      ;; Increment counter and return document ID
      (var-set document-counter (+ document-id u1))
      (ok document-id)
    )
  )
)

;; Verify a document
(define-public (verify-document (document-id uint))
  (let ((document-data (map-get? documents { document-id: document-id })))
    (if (is-some document-data)
      (begin
        (map-set documents
          { document-id: document-id }
          (merge (unwrap-panic document-data) {
            verified: true,
            timestamp: block-height
          })
        )
        (ok true)
      )
      (err u1)
    )
  )
)

;; Get document details
(define-read-only (get-document (document-id uint))
  (map-get? documents { document-id: document-id })
)

;; Get all documents for a skill
(define-read-only (get-skill-documents (skill-id uint))
  (default-to { document-ids: (list) } (map-get? skill-documents { skill-id: skill-id }))
)

;; Get all documents by a practitioner
(define-read-only (get-practitioner-documents (practitioner-id principal))
  (default-to { document-ids: (list) } (map-get? practitioner-documents { practitioner-id: practitioner-id }))
)

;; Get the total number of documents
(define-read-only (get-document-count)
  (var-get document-counter)
)

