.data

# liste de nombres
.align 1
tableau: .space 40

# messages
msg1: .asciiz "Entrez les 20 chiffres:\n"
msg2: .asciiz "> "
comma: .asciiz ", "
newline: .asciiz "\n"
	
.text
main:
	# lire tableau
	la $a0, tableau
	li $a1, 5
	jal lire_tableau
	
	# trier tableau
	la $a0, tableau
	li $a1, 5
	jal trier_tableau
	
	# afficher tableau
	la $a0, tableau
	li $a1, 5
	jal afficher_tableau
	
	j done
	
lire_tableau:
	# $t0 addresse du tableau
	# $t1 nombre d'éléments
	# $t2 compteur de la boucle
	move $t0, $a0
	move $t1, $a1
	
	li $v0, 4
	la $a0, msg1
	syscall
	
	li $t2, 0
	j lire_tableau_loop

lire_tableau_loop:
	# afficher le message
	li $v0, 4
	la $a0, msg2
	syscall
	
	# calculer l'addresse
	sll $t3, $t2, 1
	add $t3, $t3, $t0
	
	# lire l'entier
	li $v0, 5
	syscall
	
	# stocker l'entier
	sh $v0, 0($t3)
	
	# vérifier l'état de la boucle
	addi $t2, $t2, 1
	beq $t2, $t1, lire_tableau_done
	j lire_tableau_loop

lire_tableau_done:
	jr $ra
	
afficher_tableau:
	# $t0 addresse du tableau
	# $t1 nombre d'éléments
	# $t2 compteur de la boucle
	move $t0, $a0
	move $t1, $a1
	li $t2, 0
	j afficher_tableau_loop
	
afficher_tableau_loop:
	# calculer l'addresse
	sll $t3, $t2, 1
	add $t3, $t3, $t0
	
	# afficher l'entier
	li $v0, 1
	lh $a0, 0($t3)
	syscall
	
	# vérifier l'état de la boucle
	addi $t2, $t2, 1
	beq $t2, $t1, afficher_tableau_done
	
	# afficher une virgule
	li $v0, 4
	la $a0, comma
	syscall
	
	j afficher_tableau_loop
	
afficher_tableau_done:
	# afficher une virgule
	li $v0, 4
	la $a0, newline
	syscall
	jr $ra

trier_tableau:
	# t0 addresse du tableau
	# t1 nombre d'éléments
	# t2 compteur de la boucle
	move $t0, $a0
	move $t1, $a1
	li $t2, 1
	li $t8, 0
	j trier_tableau_loop
	
trier_tableau_loop:
	# $t3 = $t2 - 1
	# $t4 = tableau[$t3]
	# $t5 = tableau[]
	addi $t3, $t2, -1
	move $t4, $t2
	sll $t3, $t3, 1
	sll $t4, $t4, 1
	add $t3, $t3, $t0
	add $t4, $t4, $t0
	
	lh $t5, 0($t3)
	lh $t6, 0($t4)
	
	slt $t7, $t5, $t6 
	beq $t7, 1, trier_tableau_continue
	
	# swap
	sh $t6, 0($t3)
	sh $t5, 0($t4)
	li $t8, 1
	
	j trier_tableau_continue
	
trier_tableau_continue:
	addi $t2, $t2, 1
	beq $t2, $t1, trier_tableau_check
	j trier_tableau_loop
	
trier_tableau_check:
	beq $t8, 1, trier_tableau_again
	jr $ra
	
trier_tableau_again:
	li $t2, 0
	li $t8, 0
	j trier_tableau_loop

done:
	
