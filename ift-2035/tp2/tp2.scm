#! /usr/bin/env gsi -:dR

;;; Fichier : tp2.scm

;;; Ce programme est une version incomplete du TP2.  Vous devez uniquement
;;; changer et ajouter du code dans la première section.

;;;----------------------------------------------------------------------------

;;; Vous devez modifier cette section.  La fonction "traiter" doit
;;; être définie, et vous pouvez ajouter des définitions de fonction
;;; afin de bien décomposer le traitement à faire en petites
;;; fonctions.  Il faut vous limiter au sous-ensemble *fonctionnel* de
;;; Scheme dans votre codage (donc n'utilisez pas set!, set-car!,
;;; begin, etc).

;;; La fonction traiter reçoit en paramètre une liste de caractères
;;; contenant la requête lue et le dictionnaire des variables sous
;;; forme d'une liste d'association.  La fonction retourne
;;; une paire contenant la liste de caractères qui sera imprimée comme
;;; résultat de l'expression entrée et le nouveau dictionnaire.  Vos
;;; fonctions ne doivent pas faire d'affichage car c'est la fonction
;;; "repl" qui se charge de cela.

; effectue une opération avec reste en utilisant le modulo et le quotient.
(define (op-rem op c c1 c2)
  (let ((r (op c c1 c2)))
    (cons (modulo r 10) (quotient r 10))))

; si x est null, retourne 0, sinon (car x)
(define (car-or-0 x)
  (if (null? x) 0 (car x)))

; si x est null, retourne '(), sinon (cdr x)
(define (cdr-or-null x)
  (if (null? x) '() (cdr x)))

; extrait un chiffre ou 0 des nombres et le reste des listes ou '()
; appelle f avec les données extraites
(define (extract a b f)
  (f (car-or-0 a) (cdr-or-null a) (car-or-0 b) (cdr-or-null b)))

; compare deux nombres positifs
; retourne 'eq si a = b, 'lt si a < b et 'gt si a > b
(define (cmp-raw na nb)
  (define (impl na nb)
    (if (and (null? na) (null? nb))
      'eq
      (let ((va (car na)) (vb (car nb)))
        (cond ((< va vb) 'lt)
          ((> va vb) 'gt)
          (else (impl (cdr na) (cdr nb)))))))

  (let ((lna (length na)) (lnb (length nb)))
    (cond ((< lna lnb) 'lt)
      ((> lna lnb) 'gt)
      (else (impl (reverse na) (reverse nb))))))

; effectue une addition sur deux nombres positifs
(define (add-raw a b)
  (define (loop c a b)
    (if (and (null? a) (null? b))
      (if (zero? c) '() (cons c '()))
      (extract a b (lambda (ca la cb lb)
        (let ((r (op-rem + c ca cb)))
          (cons (car r) (loop (cdr r) la lb)))))))
  (loop 0 a b))

; effectue une addition sur n'importe quel nombre
(define (add a b)
  (let ((sa (car a))
    (sb (car b)))
      (if (equal? sa sb)
        (if (equal? sa 'pos)
          (cons 'pos (add-raw (cdr a) (cdr b)))
          (cons 'neg (add-raw (cdr a) (cdr b))))
        (if (equal? sa 'pos)
          (sub a (cons 'pos (cdr b)))
          (sub b (cons 'pos (cdr a)))))))

; effectue une soustraction sur deux nombres positifs
; a doit être supérieur a b
(define (sub-raw a b)
  (define (trim l)
    (if (null? l)
      '(0)
      (if (zero? (car l))
        (trim (cdr l))
        l)))
  (define (loop c a b)
    (if (and (null? a) (null? b)) '()
      (extract a b (lambda (ca la cb lb)
        (let ((r (- ca c)))
          (if (< r cb)
            (cons (- (+ r 10) cb) (loop 1 la lb))
            (cons (- r cb) (loop 0 la lb))))))))
  (reverse (trim (reverse (loop 0 a b)))))

; effectue une soustraction sur n'importe quel nombre
(define (sub a b)
  (define (switch n)
    (if (equal? (car n) 'pos)
      (cons 'neg (cdr n))
      (cons 'pos (cdr n))))
  (define (impl a b)
    (let ((r (cmp-raw a b)))
      (cond ((equal? r 'lt) (cons 'neg (sub-raw b a)))
        ((equal? r 'gt) (cons 'pos (sub-raw a b)))
        ((equal? r 'eq) (cons 'pos '(0))))))
  (let ((sa (car a))
    (sb (car b)))
      (if (equal? sa sb)
        (if (equal? sa 'pos)
          (impl (cdr a) (cdr b))
          (switch (impl (cdr a) (cdr b))))
        (if (equal? sa 'pos)
          (cons 'pos (add-raw (cdr a) (cdr b)))
          (cons 'neg (add-raw (cdr a) (cdr b)))))))

; sépare une liste de caratères en liste de mots (sépare sur les espaces)
; supprime aussi les espaces superflues
(define (tokens lst)
  (define (whitespace lst tokens)
    (if (null? lst)
      tokens
      (if (equal? (car lst) #\space)
        (whitespace (cdr lst) tokens)
        (token lst '() tokens))))
  (define (token lst tok tokens)
    (if (null? lst)
      (append tokens (list tok))
      (if (equal? (car lst) #\space)
        (whitespace lst (append tokens (list tok)))
        (token (cdr lst) (append tok (list (car lst))) tokens))))
  (whitespace lst '()))

; créer un nouveau noeud de l'ast
(define (node-new tag args)
  (cons tag args))

; obtenir le tag d'un noeud
(define (node-tag node)
  (car node))

; obtenir les arguments d'un noeud
(define (node-args node)
  (cdr node))

; convertir un caractère en chiffre
(define (char-to-digit c)
  (- (char->integer c) (char->integer #\0)))

; convertir un chiffre en caractères
(define (digit-to-char d)
  (integer->char (+ (char->integer #\0) d)))

; convertit une liste de caractères en nombre
(define (parse-num str)
  (define (loop str num)
    (if (null? str)
      (cons 'pos num)
      (let ((c (car str)))
        (if (char-numeric? c)
          (loop (cdr str) (cons (char-to-digit c) num))
          'err-invalid-num))))
  (loop str '()))

; convertit un nombre en liste de caractères
(define (format-num n)
  (define (loop n lst)
    (if (null? n)
      lst
      (loop (cdr n) (cons (digit-to-char (car n)) lst))))
  (if (eq? (car n) 'neg)
    (cons #\- (loop (cdr n) '()))
    (loop (cdr n) '())))

(define (parse-expr lst)
  ; construit un noeud à partir d'opérandes
  ; '(tag (op1 . op2))
  (define (parse-oper tag)
    (lambda (tok tokens ast)
      (if (null? ast)
        'err-not-enough-op
        (if (null? (cdr ast))
          'err-not-enough-op
          (let* ((op1 (car ast))
            (op2 (cadr ast))
            (node (node-new tag (cons op2 op1))))
              (dispatch (cdr tokens) (cons node (cddr ast))))))))
  ; '(num . val)
  (define (num tok tokens ast)
    (let ((r (parse-num tok)))
      (if (symbol? r)
        r
        (dispatch (cdr tokens) (cons (node-new 'num r) ast)))))
  (define ftbl (list
      (cons #\+ (parse-oper 'add))
      (cons #\- (parse-oper 'sub))
      (cons #\0 num)
      (cons #\1 num)
      (cons #\2 num)
      (cons #\3 num)
      (cons #\4 num)
      (cons #\5 num)
      (cons #\6 num)
      (cons #\7 num)
      (cons #\8 num)
      (cons #\9 num)
    ))
  (define (dispatch tokens ast)
    (if (null? tokens)
      ast
      (let* (
        (tok (car tokens))
        (kv (assoc (car tok) ftbl)))
        (if kv
          ((cdr kv) tok tokens ast)
          'err-invalid-symbol))))
  (let ((r (dispatch (tokens lst) '())))
    (if (symbol? r)
      r
      (if (> (length r) 1)
        'err-too-many-expr
        (car r)))))

(define (eval node)
  (let ((tag (node-tag node))
    (args (node-args node)))
      (cond ((equal? tag 'num) args)
        ((equal? tag 'add) (add (eval (car args)) (eval (cdr args))))
        ((equal? tag 'sub) (sub (eval (car args)) (eval (cdr args)))))))

(define (traiter expr dict)
  (if (null? expr)
    (cons '(#\newline) dict)
    (cons (append
            (format-num (eval (parse-expr expr)))
            '(#\newline))
          dict)))


;;;----------------------------------------------------------------------------
;;; Tests unitaires
(define (assert-eq d a b)
  (define (error)
    (display "Erreur dans '")
    (display d)
    (display "' : ")
    (display a)
    (display " != ")
    (display b)
    (newline))
  (if (equal? a b)
    (void)
    (error)))

(define (test)
  (display "Format: actuel != attendu\n")
  ; addition
  (assert-eq "15 + 10" (add '(pos 5 1) '(pos 0 1)) '(pos 5 2))
  (assert-eq "-15 + 10" (add '(neg 5 1) '(pos 0 1)) '(neg 5))
  (assert-eq "15 + -10" (add '(pos 5 1) '(neg 0 1)) '(pos 5))
  (assert-eq "-15 + -10" (add '(neg 5 1) '(neg 0 1)) '(neg 5 2))
  ; soustraction
  (assert-eq "15 - 10" (sub '(pos 5 1) '(pos 0 1)) '(pos 5))
  (assert-eq "-15 - 10" (sub '(neg 5 1) '(pos 0 1)) '(neg 5 2))
  (assert-eq "15 - -10" (sub '(pos 5 1) '(neg 0 1)) '(pos 5 2))
  (assert-eq "-15 - -10" (sub '(neg 5 1) '(neg 0 1)) '(neg 5))
  ; tokens
  (assert-eq "tokens simple" (tokens (string->list "4 4 +")) '((#\4) (#\4) (#\+)))
  (assert-eq "tokens espaces superflues" (tokens (string->list "  4  4  +  ")) '((#\4) (#\4) (#\+)))
  (assert-eq "tokens long" (tokens (string->list "4 =x =y")) '((#\4) (#\= #\x) (#\= #\y)))
  ; char-to-digit
  (assert-eq "char-to-digit" (char-to-digit #\2) 2)
  ; digit-to-char
  (assert-eq "digit-to-char" (digit-to-char 2) #\2)
  ; parse-num
  (assert-eq "parse-num" (parse-num (string->list "123")) '(pos 3 2 1))
  (assert-eq "parse-num invalid data" (parse-num (string->list "1a23")) 'err-invalid-num)
  ; format-num
  (assert-eq "format-num pos" (format-num '(pos 3 2 1)) '(#\1 #\2 #\3))
  (assert-eq "format-num neg" (format-num '(neg 3 2 1)) '(#\- #\1 #\2 #\3))
  ; parse-expr
  (assert-eq "parse-expr invalid num" (parse-expr (string->list "4a33")) 'err-invalid-num)
  (assert-eq "parse-expr too many expr" (parse-expr (string->list "4 4 + 4")) 'err-too-many-expr)
  (assert-eq "parse-expr not enough op" (parse-expr (string->list "4 +")) 'err-not-enough-op)
  (assert-eq "parse-expr invalid symbol" (parse-expr (string->list "a")) 'err-invalid-symbol)
  ; eval
  (assert-eq "eval simple add" (eval '(add (num . (pos 4)) . (num . (pos 4)))) '(pos 8))
  (assert-eq "eval simple sub" (eval '(sub (num . (pos 4)) . (num . (pos 4)))) '(pos 0))
  (assert-eq "eval long" (eval '(add (add (num . (pos 4)) . (num . (pos 4))) . (num . (pos 4)))) '(pos 2 1))

  (display "Tests terminés\n"))

;;;----------------------------------------------------------------------------

;;; Ne pas modifier cette section.

(define repl
  (lambda (dict)
    (print "? ")
    (let ((ligne (read-line)))
      (if (string? ligne)
          (let ((r (traiter-ligne ligne dict)))
            (for-each write-char (car r))
            (repl (cdr r)))))))

(define traiter-ligne
  (lambda (ligne dict)
    (traiter (string->list ligne) dict)))

(define main
  (lambda ()
    (repl '()))) ;; dictionnaire initial est vide

;;;----------------------------------------------------------------------------
