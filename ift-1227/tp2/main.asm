.data
#
# struct table_entry {
#     id char[16];
#     text char[256];
# };
# struct table_entry table[100];
.align 2
table: .space 27200

# char* line[256];
line: .space 256

# const char* path_table = "table.txt"
path_table: .asciiz "table.txt"
# const char* path_texte = "texte.txt"
path_texte: .asciiz "texte.txt"

.text

main:
	jal load_table

	li $v0, 10
	syscall
	
	
# Lire une ligne d'un ffichier.
#
# Change le contenu de line.
#
# Entrée:
# 	$a0 descripteur de fichier
# Sortie:
#	$v0 longueur de la string
read_line:

	# allouer le stack
	# 4 octets $s0
	# 4 octets $s1
	# 4 octets buffer
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	# $s0 descripteur de fichier
	# $s1 compteur
	move $s0, $a0
	li $s1, 0
	
	j read_line_loop
	
read_line_loop:
	# lire un octet
	li $v0, 14
	move $a0, $s0
	la $a1, 8($sp)
	li $a2, 1
	syscall
	
	lb $t2, 8($sp)
	# on a lu 0 octets, quitter
	beq $v0, 0, read_line_exit
	# on a lu LF, quitter
	beq $t2, 10, read_line_exit
	# on a lu CR, ignorer
	beq $t2, 13, read_line_loop
	
	# calculer l'adresse et stocker l'octet
	la $t3, line
	add $t4, $t3, $s1
	sb $t2, 0($t4)
	
	addi $s1, $s1, 1
	j read_line_loop
	
read_line_exit:
	# ajouter l'octet nul
	li $t2, 0
	la $t3, line
	add $t4, $t3, $s1
	sb $t2, 0($t4)
	
	# assigner $v0
	move $v0, $s1
	
	# désallouer le stack
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 12
	
	jr $ra
	
# Copie une string dans une autre location.
#
# Ajoute l'octet nul à la fin.
#
# Entrée:
#	$a0 destination
#	$a1 source
#	$a2 quantité
strcpy:
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp) 
	sw $s3, 12($sp)
	
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	li $s3, 0
	
	j strcpy_loop
	
strcpy_loop:
	beq $s2, $s3, strcpy_exit
	
	# calculer adresses
	add $t0, $s0, $s3 # dest
	add $t1, $s1, $s3 # source
	
	# copie
	lb $t2, 0($t1)
	sb $t2, 0($t0)
	
	addi $s3, $s3, 1
	j strcpy_loop
	
strcpy_exit:
	add $t0, $s0, $s3
	li $t1, 0
	sb $t1, 0($t0)

	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp) 
	lw $s3, 12($sp)
	addi $sp, $sp, 16
	jr $ra

# Trouve la position d'un octet dans une string.
#
# Entrée:
# 	$a0 adresse string
#	$a1 octet à trouver
# Sortie:
#	$v0 position, -1 si non trouvé
strpos:
	add $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	move $s0, $a0
	move $s1, $a1
	li $s2, 0
	
	j strpos_loop
	
strpos_loop:
	add $t0, $s0, $s2
	lb $t1, 0($t0)
	
	# octet nul, fin de la string
	beq $t1, 0, strpos_exit_notfound
	# octet à trouver
	beq $t1, $s1, strpos_exit_found
	
	addi $s2, $s2, 1
	j strpos_loop

strpos_exit_notfound:
	li $v0, -1
	j strpos_exit
	
strpos_exit_found:
	move $v0, $s2
	j strpos_exit
	
strpos_exit:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	addi $sp, $sp, 12
	jr $ra

load_table:
	# ouvrir le
	li $v0, 13
	la $a0, path_table
	li $a1, 0
	li $a2, 0
	syscall
	
	# save registers
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	# save file descriptor in $s0
	move $s0, $v0
	# address
	la $s1, table
	
	### call read_line
	move $a0, $s0
	jal read_line
	
	li $v0, 4
	la $a0, line
	syscall

	lw $ra, 0($sp)
	addi $sp, $sp, 12
	
	jr $ra
