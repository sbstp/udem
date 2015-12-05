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
(define (op-rem op c c1 c2 f)
  (let ((r (op c c1 c2)))
    (f (modulo r 10) (quotient r 10))))

; si x est null, retourne 0, sinon (car x)
(define (car-or-0 x)
  (if (null? x) 0 (car x)))

; si x est null, retourne '(), sinon (cdr x)
(define (cdr-or-null x)
  (if (null? x) '() (cdr x)))

; extrait un chiffre ou 0 des nombres et le reste des listes ou '()
; appelle f avec les données extraites
(define (extract-n n f)
  (f (car-or-0 n) (cdr-or-null n)))

(define (extract a b f)
  (f (car-or-0 a) (cdr-or-null a) (car-or-0 b) (cdr-or-null b)))

; ajoute un élément à une liste
(define (append-element l e)
  (append l (cons e '())))

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
  (define (loop c a b n)
    (if (and (null? a) (null? b))
      (if (zero? c) n (append-element n c))
      (extract a b (lambda (ca la cb lb)
        (op-rem + c ca cb (lambda (res rem)
          (loop rem la lb (append-element n res))))))))
  (loop 0 a b '()))

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
  (define (loop c a b n)
    (if (and (null? a) (null? b)) n
      (extract a b (lambda (ca la cb lb)
        (let ((r (- ca c)))
          (if (< r cb)
            (loop 1 la lb (append-element n (- (+ r 10) cb)))
            (loop 0 la lb (append-element n (- r cb)))))))))
  (reverse (trim (reverse (loop 0 a b '())))))

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

; effectue une multiplication d'un nombre par un chiffre et une puissance de 10
(define (mul-factor-power n fact p)
  (define (inc-power p)
    (if (equal? p 0) '()
      (cons 0 (inc-power (- p 1)))))
  (define (loop r c fact n)
    (if (null? n)
      (if (zero? c) r (append-element r c))
      (extract-n n (lambda(cn ln)
        (op-rem + c (* cn fact) 0 (lambda (res rem)
          (loop (append-element r res) rem fact ln)))))))
  (if (equal? fact 0) '(0)
    (loop (inc-power p) 0 fact n)))

; effectue une multiplication sur n'importe quel nombre
(define (mul a b)
  (define (loop r p a b)
    (if (null? a) r
      (extract-n a (lambda (ca la)
        (let ((part-r (mul-factor-power b ca p)))
          (let ((new-r (add-raw r part-r)))
            (loop new-r (+ p 1) la b)))))))
  (let ((sa (car a))
    (sb (car b)))
      (if (equal? sa sb)
        (cons 'pos (loop '(0) 0 (cdr a) (cdr b)))
        (cons 'neg (loop '(0) 0 (cdr a) (cdr b))))))

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
      (append-element tokens tok)
      (if (equal? (car lst) #\space)
        (whitespace lst (append-element tokens tok))
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

; vérifie si le caractère est un nom de variable valide
(define (is-var-name c)
  (and (char-alphabetic? c) (char-lower-case? c)))

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
  (append (cond
    ((or (equal? n '(neg 0)) (equal? n '(pos 0))) '(#\0))
    ((equal? (car n) 'neg) (cons #\- (loop (cdr n) '())))
    (else (loop (cdr n) '()))) '(#\newline)))

(define (parse-expr lst)
  ; construit un noeud d'assignation
  (define (assign tok tokens ast)
    (if (equal? (length tok) 2)
      (if (is-var-name (cadr tok))
        (if (not (null? ast))
          (dispatch (cdr tokens) (cons (node-new 'ass (cons (cadr tok) (car ast))) (cdr ast)))
          'err-not-enough-op)
        'err-invalid-varname)
      'err-invalid-syntax))
  ; construit un noeud à partir d'opérandes
  ; '(tag (op1 . op2))
  (define (oper tag)
    (lambda (tok tokens ast)
      (if (null? ast)
        'err-not-enough-op
        (if (null? (cdr ast))
          'err-not-enough-op
          (let* ((op1 (car ast))
            (op2 (cadr ast))
            (node (node-new tag (cons op2 op1))))
              (dispatch (cdr tokens) (cons node (cddr ast))))))))
  ; construit un noeud d'addition
  (define add (oper 'add))
  ; construit un noeud de soustraction
  (define sub (oper 'sub))
  ;construit un noeud de multiplication
  (define mul (oper 'mul))
  ; construit un noeud de nombre
  (define (num tok tokens ast)
    (let ((r (parse-num tok)))
      (if (symbol? r)
        r
        (dispatch (cdr tokens) (cons (node-new 'num r) ast)))))

  ; construit un noeud d'utilisation de variable
  (define (use tok tokens ast)
    (let ((node (node-new 'use (car tok))))
      (dispatch (cdr tokens) (cons node ast))))

  ; retourne la fonction d'analyse en fonction du caractère donné
  (define (dispatch-fn c)
    (cond
      ((equal? c #\=) assign)
      ((equal? c #\+) add)
      ((equal? c #\-) sub)
      ((equal? c #\*) mul)
      ((char-numeric? c) num)
      ((is-var-name c) use)
      (else 'err-invalid-symbol)))

  ; automate d'analyse d'expression, centre nerveux
  (define (dispatch tokens ast)
    (if (null? tokens)
      ast
      (let* ((tok (car tokens))
        (f (dispatch-fn (car tok))))
          (if (symbol? f)
            f
            (f tok tokens ast)))))

  ; départ de l'analyse.
  (let ((r (dispatch (tokens lst) '())))
    (if (symbol? r)
      r
      (if (> (length r) 1)
        'err-too-many-expr
        (car r)))))

; remplace une clef si elle existe, sinon elle est ajouté
(define (insert-or-replace dict k v)
  (if (null? dict)
    (cons (cons k v) '())
    (if (equal? (caar dict) k)
      (cons (cons k v) (cdr dict))
      (cons (car dict) (insert-or-replace (cdr dict) k v)))))

; évaluer une expression à partir de l'asa
; retourne une pair avec la valeur à gauche et les variables à droite
(define (eval node vars)
  ; évaluer une assignation
  (define (eval-ass args vars)
    (let ((v (eval (cdr args) vars)))
      (if (symbol? v)
        v
        (cons (car v) (insert-or-replace (cdr v) (car args) (car v))))))
  ; évaluer un opérateur d'arité 2
  (define (eval-op op)
    (lambda (args vars)
      (let ((v1 (eval (car args) vars)))
        ; erreur?
        (if (symbol? v1)
          v1
          (let ((v2 (eval (cdr args) (cdr v1))))
            ; erreur?
            (if (symbol? v2)
              v2
              (cons (op (car v1) (car v2)) (cdr v2))))))))
  ; évaluer un nombre
  (define (eval-num args vars)
    (cons args vars))
  ; évaluer une expression d'utilisation de variable
  (define (eval-use args vars)
    (let ((r (assoc args vars)))
      (if r
        (cons (cdr r) vars)
        'err-undefined-var)))
  ; dispatch table
  (define table
    (list
      (cons 'ass eval-ass)
      (cons 'add (eval-op add))
      (cons 'sub (eval-op sub))
      (cons 'mul (eval-op mul))
      (cons 'num eval-num)
      (cons 'use eval-use)))
  (let ((r (assoc (node-tag node) table)))
    (if r
      ((cdr r) (node-args node) vars)
      'err-invalid-ast-tag)))

(define (format-parser-error err)
  (define table (list
    (cons 'err-not-enough-op "Nombre d'opérandes insuffisant.")
    (cons 'err-invalid-syntax "Syntaxe invalide.")
    (cons 'err-invalid-varname "Nom de variable invalide.")
    (cons 'err-invalid-num "Nombre invalide.")
    (cons 'err-too-many-expr "La ligne contient plus qu'une expression.")
    (cons 'err-invalid-symbol "Symbole invalide.")))

  (let ((r (assoc err table)))
    (if r
      (append (string->list (cdr r)) '(#\newline))
      (error err))))

(define (format-eval-error err)
  (if (equal? err 'err-undefined-var)
    (string->list "Variable inconnue utilisée\n")
    (error err)))

; traiter l'expression reçue
(define (traiter expr dict)
  (if (null? expr)
    (cons '(#\newline) dict)
    (let ((ast (parse-expr expr)))
      (if (symbol? ast)
        (cons (format-parser-error ast) dict)
        (let ((r (eval ast dict)))
          (if (symbol? r)
            (cons (format-eval-error r) dict)
            (cons (format-num (car r)) (cdr r))))))))

;;;----------------------------------------------------------------------------
;;; Tests unitaires
(define (assert-eq d a b)
  (define (error)
    (display "----\n")
    (display "Erreur dans '")
    (display d)
    (display ":\n")
    (display "Actuel:    ")
    (pp a)
    (display "Attendu:   ")
    (pp b))
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
  ;multiplication
  ;signe
  (assert-eq "1 * 1" (mul '(pos 1) '(pos 1)) '(pos 1))
  (assert-eq "-1 * 1" (mul '(neg 1) '(pos 1)) '(neg 1))
  (assert-eq "1 * -1" (mul '(pos 1) '(neg 1)) '(neg 1))
  (assert-eq "-1 * -1" (mul '(neg 1) '(neg 1)) '(pos 1))
  ;simple (sans retenue et nombre de puissance 0)
  (assert-eq "1 * 2" (mul '(pos 1) '(pos 2)) '(pos 2))
  (assert-eq "2 * 1" (mul '(pos 1) '(pos 2)) '(pos 2))
  ;complexe (avec retenue et nombre puissance 1)
  (assert-eq "1 * 2" (mul '(pos 5) '(pos 3)) '(pos 5 1))
  (assert-eq "2 * 1" (mul '(pos 3) '(pos 5)) '(pos 5 1))
  ;complexe (avec retenue et nombre puissance 2+)
  (assert-eq "1 * 2" (mul '(pos 1 2 3 4 5 6 7 8 0 9) '(pos 0 9 8 7 6 5 4 3 2 1)) '(pos 0 9 6 2 5 3 6 2 1 0 2 2 6 2 3 9 1 2 1 1))
  (assert-eq "1 * 2" (mul '(pos 0 9 8 7 6 5 4 3 2 1) '(pos 1 2 3 4 5 6 7 8 0 9)) '(pos 0 9 6 2 5 3 6 2 1 0 2 2 6 2 3 9 1 2 1 1))
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
  (assert-eq "format-num pos" (format-num '(pos 3 2 1)) '(#\1 #\2 #\3 #\newline))
  (assert-eq "format-num neg" (format-num '(neg 3 2 1)) '(#\- #\1 #\2 #\3 #\newline))
  (assert-eq "format-num pos 0" (format-num '(pos 0)) '(#\0 #\newline))
  (assert-eq "format-num neg 0" (format-num '(neg 0)) '(#\0 #\newline))
  ; parse-expr
  (assert-eq "parse-expr ass" (parse-expr (string->list "4 =x")) '(ass . (#\x . (num . (pos 4)))))
  (assert-eq "parse-expr num" (parse-expr (string->list "4")) '(num . (pos 4)))
  (assert-eq "parse-expr add" (parse-expr (string->list "4 4 +")) '(add . ((num . (pos 4)) . (num . (pos 4)))))
  (assert-eq "parse-expr sub" (parse-expr (string->list "4 4 -")) '(sub . ((num . (pos 4)) . (num . (pos 4)))))
  (assert-eq "parse-expr mul" (parse-expr (string->list "4 4 *")) '(mul . ((num . (pos 4)) . (num . (pos 4)))))
  (assert-eq "parse-expr use" (parse-expr (string->list "a")) '(use . #\a))
  ; parse-expr (erreurs)
  (assert-eq "parse-expr assign not enough op" (parse-expr (string->list "=x")) 'err-not-enough-op)
  (assert-eq "parse-expr assign invalid syntax" (parse-expr (string->list "4 =abc")) 'err-invalid-syntax)
  (assert-eq "parse-expr assign invalid varname" (parse-expr (string->list "4 =A")) 'err-invalid-varname)
  (assert-eq "parse-expr num invalid" (parse-expr (string->list "4a33")) 'err-invalid-num)
  (assert-eq "parse-expr too many expr" (parse-expr (string->list "4 4 + 4")) 'err-too-many-expr)
  (assert-eq "parse-expr not enough op" (parse-expr (string->list "4 +")) 'err-not-enough-op)
  (assert-eq "parse-expr invalid symbol" (parse-expr (string->list "!")) 'err-invalid-symbol)
  ; insert-or-replace
  (assert-eq "insert-or-replace existe" (insert-or-replace '((b . 4) (a . 2)) 'a 3) '((b . 4) (a . 3)))
  (assert-eq "insert-or-replace existe pas" (insert-or-replace '() 'a 3) '((a . 3)))
  ; eval
  (assert-eq "eval simple add" (eval '(add . ((num . (pos 4)) . (num . (pos 4)))) '()) '((pos 8)))
  (assert-eq "eval simple sub" (eval '(sub . ((num . (pos 4)) . (num . (pos 4)))) '()) '((pos 0)))
  (assert-eq "eval long" (eval '(add . ((add . ((num . (pos 4)) . (num . (pos 4)))) . (num . (pos 4)))) '()) '((pos 2 1)))
  (assert-eq "eval assign" (eval '(ass . (#\a . (num . (pos 4)))) '()) '((pos 4) . ((#\a . (pos 4)))))
  (assert-eq "eval use" (eval '(use . #\a) '((#\a . (pos 4)))) '((pos 4) . ((#\a . (pos 4)))))
  (assert-eq "eval undef var" (eval '(use . #\a) '()) 'err-undefined-var)
  (assert-eq "eval undef var ass" (eval '(ass . (#\a . (use #\b))) '()) 'err-undefined-var)
  (assert-eq "eval undef var op" (eval '(ass . (#\a . (add . ((num . (pos 4)) . (use #\b))))) '()) 'err-undefined-var)

  ; tests d'intégration
  (assert-eq "intégration changement valeur" (eval (parse-expr (string->list "4 =x")) '((#\x . (pos 2)))) '((pos 4) . ((#\x . (pos 4)))))
  (assert-eq "intégration double assignation" (eval (parse-expr (string->list "2 =x 4 =x *")) '()) '((pos 8) . ((#\x . (pos 4)))))


  (display "----\n")
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
