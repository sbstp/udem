# IFT-1227 - TP1 - Question 2
# Gabriel Lemyre
# Simon Bernier St-Pierre


.data
# liste de nombres
.align 1
tableau: .space 40

# messages
msg1: .asciiz "Entrez les 20 chiffres:\n"
prompt: .asciiz "> "
comma: .asciiz ", "
newline: .asciiz "\n"
	
.text
main:
	# lire tableau
	la $a0, tableau
	li $a1, 20
	jal lire_tableau
	
	# trier tableau
	la $a0, tableau
	li $a1, 20
	jal trier_tableau
	
	# afficher tableau
	la $a0, tableau
	li $a1, 20
	jal afficher_tableau
	
	# exit
	li $v0, 10
	syscall


##############
# lire tableau	
lire_tableau:
	# $t0 addresse du tableau
	# $t1 nombre d'éléments
	# $t2 compteur de la boucle
	# $t3 addresse de l'élément
	
	move $t0, $a0
	move $t1, $a1
	
	li $v0, 4
	la $a0, msg1
	syscall
	
	li $t2, 0
	j lire_tableau_loop

lire_tableau_loop:
	# afficher le prompt
	li $v0, 4
	la $a0, prompt
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


##################
# afficher_tableau	
afficher_tableau:
	# $t0 addresse du tableau
	# $t1 nombre d'éléments
	# $t2 compteur de la boucle
	# $t3 addresse de l'élément
	
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
	# afficher une nouvelle ligne
	li $v0, 4
	la $a0, newline
	syscall
	jr $ra


###############
# trier_tableau
trier_tableau:
	# $t0 addresse du tableau
	# $t1 nombre d'éléments
	# $t2 compteur de la boucle
	# $t3 est-ce que des éléments ont été échangés ?
	# $t4 adresse $t2 - 1
	# $t5 adresse $t2
	# $t6 valeur à l'adresse $t4
	# $t7 valeur à l'adresse $t5
	# $t8 est-ce que $t6 < $t7 ?
	
	move $t0, $a0
	move $t1, $a1
	j trier_tableau_again
	
trier_tableau_again:
	li $t2, 1
	li $t3, 0
	j trier_tableau_loop
	
trier_tableau_loop:
	addi $t4, $t2, -1
	move $t5, $t2
	sll $t4, $t4, 1
	sll $t5, $t5, 1
	add $t4, $t4, $t0
	add $t5, $t5, $t0
	
	lh $t6, 0($t4)
	lh $t7, 0($t5)
	
	sle $t8, $t6, $t7 
	beq $t8, 1, trier_tableau_continue
	
	# swap
	sh $t7, 0($t4)
	sh $t6, 0($t5)
	li $t3, 1
	
	j trier_tableau_continue
	
trier_tableau_continue:
	# vérifier si on a atteint le compteur
	addi $t2, $t2, 1
	beq $t2, $t1, trier_tableau_check
	j trier_tableau_loop
	
trier_tableau_check:
	# vérifier si un élément a été trié
	beq $t3, 1, trier_tableau_again
	jr $ra
