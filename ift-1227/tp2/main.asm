# Simon Bernier St-Pierre
# Gabriel Lemyre
# Encodage: UTF-8

.data
#
# struct table_entry {
#     int id;
#     int len;
#     char text[256];
# };

.align 2
# int table_size;
table_size: .space 4

# struct table_entry table[100];
table: .space 26400

# char* line[256];
line: .space 256

# char* outbuff[8192]
outbuff: .space 8192

# const char* path_table = "table.txt"
path_table: .asciiz "table.txt"
# const char* path_texte = "texte.txt"
path_texte: .asciiz "texte.txt"

.text

main:
	jal table_load
	jal text_load

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
	beq $t2, '\n', read_line_exit
	# on a lu CR, ignorer
	beq $t2, '\r', read_line_loop

	# calculer l'adresse et stocker l'octet
	la $t3, line
	add $t3, $t3, $s1
	sb $t2, 0($t3)

	addi $s1, $s1, 1
	j read_line_loop

read_line_exit:
	# ajouter l'octet nul
	li $t2, 0
	la $t3, line
	add $t3, $t3, $s1
	sb $t2, 0($t3)

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

# Convertir une string en int
#
# Entrée:
#	$a0 adresse string
#	$a0 taille string
# Sortie:
#	$v0 valeur en int
stoi:
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)

	move $s0, $a0 # adresse string
	move $s1, $a1 # taille string
	li $s2, 0 # compteur
	li $s3, 0 # valeur

	j stoi_loop

stoi_loop:
	beq $s2, $s1, stoi_exit
	mul $s3, $s3, 10

	# lire le caractère
	add $t0, $s0, $s2
	lb $t0, 0($t0)

	# char -> int
	sub $t0, $t0, '0'
	add $s3, $s3, $t0

	addi $s2, $s2, 1
	j stoi_loop

stoi_exit:
	move $v0, $s3

	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	addi $sp, $sp, 16
	jr $ra

# Charger la table en mémoire à partir du fichier.
#
# Utilise le fichier table.txt
#
# Modifie le bloc de mémoire table. Utilise 264 octets par entrée,
# 4 pour le nombre, 4 pour la taille de la string, et 256 pour la string.
table_load:
	addi $sp, $sp, -28
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)


	# ouvrir le fichier
	li $v0, 13
	la $a0, path_table
	li $a1, 0
	li $a2, 0
	syscall

	move $s0, $v0 # descripteur de fichier
	la $s1, table # adresse de la table
	li $s2, 0 # compteur

	j table_load_loop

table_load_loop:
	move $a0, $s0
	jal read_line

	# regarder si eof
	beq $v0, 0, table_load_exit

	move $s3, $v0 # nombre de caractères lus

	la $a0, line
	li $a1, ','
	jal strpos

	move $s4, $v0 # position de la virgule

	# calculer l'adresse de base
	mul $s5, $s2, 260
	add $s5, $s1, $s5

	# string->int
	la $a0, line
	move $a1, $s4
	jal stoi

	# stocker le numéro
	sw $v0, 0($s5)

	# adresse source
	# ligne + position virgule + 2
	la $t1, line
	add $t1, $t1, $s4
	addi $t1, $t1, 2 # sauter par dessu ,"

	# calculer taille de la string
	# longueur ligne - position virgule - 3
	addi $t2, $s3, -3
	sub $t2, $t2, $s4

	# stocker la taille de la string
	sw $t2, 4($s5)

	# stocker la string
	la $a0, 8($s5)
	move $a1, $t1
	move $a2, $t2
	jal strcpy

	addi $s2, $s2, 1
	j table_load_loop

table_load_exit:
	# sauvegarder taille de la table
	la $t0, table_size
	sw $s2, 0($t0)

	# fermer le fd
	li $v0, 16
	move $a0, $s0
	syscall

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	addi $sp, $sp, 28

	jr $ra

# Trouve un élément de la table par numéro
#
# Entrée:
#	$a0 numéro
# Sortie:
#  	$v0 taille de la string ou -1 si non trouvé
# 	$v1 adresse string
table_lookup:
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)

	move $s0, $a0 # numéro
	li $s1, 0 # compteur
	la $s2, table # adresse table

	la $t0, table_size
	lw $s3, 0($t0) # nombre éléments

	j table_lookup_loop

table_lookup_loop:
	beq $s1, $s3, table_lookup_exit_notfound

	# calculer adresse
	mul $t0, $s1, 260
	add $t0, $t0, $s2

	# compare numéro
	lw $t1, 0($t0)
	beq $t1, $s0, table_lookup_exit_found

	addi $s1, $s1, 1
	j table_lookup_loop

table_lookup_exit_notfound:
	li $v0, -1
	j table_lookup_exit

table_lookup_exit_found:
	lw $v0, 4($t0)
	la $v1, 8($t0)
	j table_lookup_exit

table_lookup_exit:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	addi $sp, $sp, 16
	jr $ra


# Remplace les numéros par le texte correspondant.
#
# La string formatté est envoyée dans outbuff.
#
# Sortie:
#	$v0 longueur de outbuff
text_format_line:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	la $s0, outbuff # adresse dans la destination
	la $s1, line # adresse dans la source
	add $s2, $s1, $a0 # adresse fin de la ligne

	j text_format_line_loop

text_format_line_loop:
	# trouver position du guillemet ouvrant
	move $a0, $s1
	li $a1, '"'
	jal strpos

	beq $v0, -1, text_format_line_exit

	# copier tout avant guillemet
	move $a0, $s0
	move $a1, $s1
	move $a2, $v0
	jal strcpy

	# avancer dans la destination
	add $s0, $s0, $v0

	# avancer dans la source
	add $s1, $s1, $v0
	addi $s1, $s1, 1

	# trouver position du guillemet fermant
	move $a0, $s1
	li $a1, '"'
	jal strpos
	move $s3, $v0

	# convertir le nombre en numéro
	move $a0, $s1
	move $a1, $v0
	jal stoi

	# avancer dans la source
	add $s1, $s1, $s3
	addi $s1, $s1, 1

	# trouver le texte correspondant au numéro
	move $a0, $v0
	jal table_lookup

	# copier l'élément de la table
	move $s3, $v0

	move $a0, $s0
	move $a1, $v1
	move $a2, $s3
	jal strcpy

	# avancer la destination
	add $s0, $s0, $s3

	j text_format_line_loop

text_format_line_exit:
	# copier reste de la ligne
	sub $s3, $s2, $s1
	move $a0, $s0
	move $a1, $s1
	move $a2, $s3
	jal strcpy

	# avancer dans la destination
	add $s0, $s0, $s3

	# calculer le nombre de caractères dans outbuff
	la $t0, outbuff
	sub $v0, $s0, $t0

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra

# Remplace le premier espace trouvé par un saut de ligne en parcourant la string à l'envers.
#
# Entrée:
#	$a0 pointeur dans la string outbuff
# Sortie:
#	$v0 nouvelle position du pointeur
text_replace_space:
	addi $sp, $sp, -4
	sw $s0, 0($sp)

	move $s0, $a0

	j text_replace_space_loop

text_replace_space_loop:
	lb $t0, 0($s0)
	beq $t0, ' ', text_replace_space_exit
	addi $s0, $s0, -1
	j text_replace_space_loop

text_replace_space_exit:
	li $t0, '\n'
	sb $t0, 0($s0)

	# la nouvelle position du pointeur
	move $v0, $s0
	addi $v0, $v0, 1

	lw $s0, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Affiche le contenu de la ligne avec reformattage.
#
# La séparation se fait sur les mots. Le dernier espace avant 100 caractères
# est remplacé par un saut de ligne.
#
# Entrée
#	$a0 longueur de la ligne
text_display_line:
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	la $s0, outbuff
	add $s1, $s0, $a0

	j text_display_line_loop

text_display_line_loop:
	# si il reste moins de 100 caractères à afficher, on quitte
	sub $t0, $s1, $s0
	sle	$t0, $t0, 100
	beq $t0, 1, text_display_line_exit

	# remplacer le dernier espace avant 100 caractères
	add $a0, $s0, 100
	jal text_replace_space

	move $s0, $v0

	j text_display_line_loop

text_display_line_exit:
	li $v0, 4
	la $a0, outbuff
	syscall

	li $v0, 11
	li $a0, '\n'
	syscall

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Charge le fichier texte et formatte les lignes du fichier une par une.
text_load:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# ouvrir le fichier
	li $v0, 13
	la $a0, path_texte
	li $a1, 0
	li $a2, 0
	syscall

	move $s1, $v0 # descripteur de fichier

	j text_load_loop

text_load_loop:
	# lire une ligne
	move $a0, $s1
	jal read_line

	# 0 caractères lus, eof
	beq $v0, 0, text_load_exit

	# formattage
	move $a0, $v0
	jal text_format_line

	# affichage
	move $a0, $v0
	jal text_display_line

	j text_load_loop

text_load_exit:
	# fermer le fd
	li $v0, 16
	move $a0, $s0
	syscall

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
