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

; 214
; 999

(define (op-rem op c c1 c2)
  (let ((r (op c c1 c2)))
    (cons (modulo r 10) (quotient r 10))))

(define (car-or-0 x)
  (if (null? x) 0 (car x)))

(define (cdr-or-null x)
  (if (null? x) '() (cdr x)))

;;; extrait un chiffre ou 0 des nombres et le reste des listes ou '()
(define (extract a b f)
  (f (car-or-0 a) (cdr-or-null a) (car-or-0 b) (cdr-or-null b)))

(define (add a b)
  ;;; étape récursive
  (define (loop c a b)
    (if (and (null? a) (null? b))
      (if (zero? c) '() (cons c '()))
      (extract a b (lambda (ca la cb lb)
        (let ((r (op-rem + c ca cb)))
          (cons (car r) (loop (cdr r) la lb)))))))
  (loop 0 a b))

; TODO meilleur implémentation
; retourne 'eq si a = b, 'lt si a < b et 'gt si a > b
(define (cmp na nb)
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

(define (sub a b)
  (define (loop c a b)
    (if (and (null? a) (null? b)) '()
      (extract a b (lambda (ca la cb lb)
        (let ((r (- ca c)))
          (if (< r cb)
            (cons (- (+ r 10) cb) (loop 1 la lb))
            (cons (- r cb) (loop 0 la lb))))))))
  (if (eq? (cmp a b) 'lt)
    (loop 0 b a)
    (loop 0 a b)))

(define (display-num n)
  (if (null? n)
    (void)
    ((lambda (n)
      (display-num (cdr n))
      (display (car n)))
          n)))

(define traiter
  (lambda (expr dict)
    (cons (append (string->list "*** le programme est ")
                  '(#\I #\N #\C #\O #\M #\P #\L #\E #\T #\! #\newline)
                  (string->list "*** la requete lue est: ")
                  expr
                  (string->list "\n*** nombre de caractères: ")
                  (string->list (number->string (length expr)))
                  '(#\newline))
          dict)))

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
