# Simon Bernier St-Pierre
# Gabriel Lemyre
# Encodage: UTF-8

.data
#
# struct table_entry {
#     int id;
#     int len;
#     char *text;
# };

.align 2
# int table_size;
table_size: .space 4

# struct table_entry table[100];
table: .space 1200

# char* line[256];
line: .space 256

# char* outbuff[8192]
outbuff: .space 8192

# const char* path_table = "table.txt"
path_table: .asciiz "table.txt"
# const char* path_texte = "texte.txt"
path_texte: .asciiz "texte.txt"

###############
# malloc/free #
###############
#
# un descripteur contient 3 entiers :
#   - le pointeur sur le bloc, 
#   - la taille du bloc en octets, 
#   - l'état du bloc: (0 = libre, 1 = alloué)
#
descript: 	.space 	12000	# 3 entiers = 12, 1000 descripteurs
nb_descript:	.word	0 	# initialement, pas de descripteurs dans la table de descripteurs.

.text

main:
	jal table_load
	jal text_load

	li $v0, 10
	syscall


# Lire une ligne d'un fichier.
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
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)

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
	la $s6, line
	add $s6, $s6, $s4
	addi $s6, $s6, 2 # sauter par dessu ,"

	# calculer taille de la string
	# longueur ligne - position virgule - 3
	addi $s7, $s3, -3
	sub $s7, $s7, $s4

	# stocker la taille de la string
	sw $s7, 4($s5)
	
	# stocker la string
	addi $a0, $s7, 1 # +1 pour octet nul
	jal malloc
	
	sw $v0, 8($s5)

	move $a0, $v0
	move $a1, $s6
	move $a2, $s7
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
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36

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
	lw $v1, 8($t0)
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


################
# malloc, free #
################

# Fonction $v0 = MALLOC ($a0)
# 
# Cette fonction retourne un pointeur sur un bloc de mémoire de mémoire dynamique
# $a0 contient le nombre d'octets désirés
# resultat:
# $v0 contient l'adresse du bloc demandé.
malloc:
	add	$sp,$sp,-16
	sw	$ra,12($sp)
	sw	$a0,8($sp)	# ici on preserve la taille du bloc désiré
	sw	$s0,4($sp)	# $s0 sera utilisé pour adresser le tableau de descripteurs
	sw	$s1,0($sp)	# $s1 sera utilisé pour le nombre de descripteurs dans le tableau.

	la	$s1,nb_descript
	lw	$t1,0($s1)
	bne	$t1,$0,au_moins_un_descripteur
	li	$v0,9		## sbrk
	li	$a0,4096
	syscall
	
	la	$s0,descript	# au début du tableau
	sw	$v0,0($s0)	# le pointeur
	sw	$a0,4($s0)	# la taille du bloc
	sw	$0,8($s0)	# le bloc est libre
	la	$s1,nb_descript	# il faut aussi indiquer qu'on a maintenant un descripteur dans le tableau
	li	$t1,1
	sw	$t1,0($s1)

au_moins_un_descripteur:
	lw	$a0,8($sp)	# on récupère la taille du bloc désiré qu'on avait sauvegardé au début.
	jal	cherche_bloc_libre
	li	$t0,-1
	bne	$v0,$t0,bloc_trouve
# pas de mémoire disponible.
# on demande au système d'exploitation un autre bloc de mémoire.
	li	$v0,9		## sbrk
	li	$a0,4096
	syscall
	
	la	$s0,descript	# au début du tableau
	la	$s1,nb_descript
	lw	$t1,0($s1)
	mul	$t2,$t1,12	# chaque descripteur occupe 12 octets.
	add	$s0,$s0,$t2	# $s0 contient maintenant l'adresse de descript[nb_descript]
	sw	$v0,0($s0)	# le pointeur
	sw	$a0,4($s0)	# la taille du bloc
	sw	$0,8($s0)	# le bloc est libre
	addi	$t1,$t1,1	# il faut aussi indiquer qu'on a maintenant un descripteur dans le tableau
	sw	$t1,0($s1)
# on devrait être en mesure d'allouer le bloc maintenant.
	lw	$a0,8($sp)	# on récupère la taille du bloc désiré qu'on avait sauvegardé au début.
	jal	cherche_bloc_libre
	li	$t0,-1
	bne	$v0,$t0,bloc_trouve
# pas de mémoire disponible.
# c'est pas normal.
	j	fin_malloc	# $v0 = -1

bloc_trouve:			# le bloc trouvé est de taille supérieure ou égal à la taille demandée.
	# si le bloc est de taille égale à la taille désirée, on retourne l'adresse pointée par le bloc.
	lw	$a0,8($sp)	# on récupère la taille du bloc désiré qu'on avait sauvegardé au début.
	la	$s0,descript	# l'adresse du tableau
	mul	$t0,$v0,12	# $v0 contient l'indice du bloc libre trouvé dans le tableau
	add	$s0,$s0,$t0	
	lw	$t1,4($s0)	# la taille du bloc
	beq	$t1,$a0,blocs_egaux
	
	# on a besoin de découper le bloc trouvé en 2 blocs
	add	$s0,$v0,$0	# on garde une copie de $v0 dans $s0
	add	$a0,$v0,$0	# on met l'indice du descripteur dans $a0
	jal	inserer_un_descripteur
	la	$s0,descript
	addi	$t3,$0,12
	mul	$t0,$v0,$t3
	add	$s0,$s0,$t0
	lw	$a0,8($sp)	# on récupère la taille du bloc désiré qu'on avait sauvegardé au début.
	lw	$a1,4($s0)	# on récupère la taille du bloc qu'on est en train de découper
	sw	$a0,4($s0)	# la taille du bloc = la taille demandée.
	addi	$t1,$0,1	# le bloc est maintenant occupé
	sw	$t1,8($s0)
	lw	$t1,12($s0)	# l'adresse du bloc pointé par le nouveau descripteur
	add	$t1,$t1,$a0	# la nouvelle adresse = l'adresse du bloc découpé + la taille du bloc demandé.
	sw	$t1,12($s0)
	sub	$a1,$a1,$a0	# la taille qui reste = la taille du bloc découpé - la taille du bloc demandé.
	sw	$a1,16($s0)
	sw	$0,20($s0)
	lw	$v0,0($s0)	# on retourne le bloc découpé
	j	fin_malloc
blocs_egaux:
	li	$t0,1		# indique que le bloc est occupé
	sw	$t0,8($s0)
	lw	$v0,0($s0)	# retourner l'adresse du bloc alloué.
fin_malloc:
	lw	$s1,0($sp)
	lw	$s0,4($sp)
	lw	$a0,8($sp)
	lw	$ra,12($sp)
	add	$sp,$sp,16
	jr	$ra
	
# Fonction $v0 = cherche_bloc_libre ($a0)
# paramètres:
#	$a0 contient le nombre d'octets désirés.
# Retourne $v0 = l'index dans le tableau de descripteurs du bloc trouvé
#		 -1 si aucun bloc trouvé.
#
# cette fonction recherche le premier bloc libre de taille supérieure ou égale à la taille demandée.
#

cherche_bloc_libre:
	add	$sp,$sp,-12
	sw	$ra,8($sp)
	sw	$s0,4($sp)
	sw	$s1,0($sp)

	la	$s0,descript	# le tableau
	la	$s1,nb_descript
	lw	$t1,0($s1)	# le nombre de descripteurs 
	add	$t2,$0,$0	# indice de boucle
cherche_boucle:
	beq	$t2,$t1,cherche_bloc_pas_trouve
	
	lw	$t0,8($s0)	# l'état du bloc est-il libre?
	bne	$t0,$0,cherche_bloc_suivant	# pas libre
	lw	$t0,4($s0)	# le bloc est-il suffisamment grand?
	slt	$t3,$t0,$a0
	bne	$t3,$0,cherche_bloc_suivant
# ici on a trouvé un bloc plus grand ou égal à la taille désirée et libre.
	add	$v0,$t2,$0	# $v0 contient l'indice dans le tableau de descripteurs.
	j	cherche_bloc_fin	
cherche_bloc_suivant:	
	addi	$t2,$t2,1	# indice de boucle + 1
	addi	$s0,$s0,12	# taille d'un descripteur
	j	cherche_boucle
	
cherche_bloc_pas_trouve:
	li	$v0,-1		# indique pas de bloc trouvé
	j	cherche_bloc_fin
cherche_bloc_fin:
	lw	$s1,0($sp)
	lw	$s0,4($sp)
	lw	$ra,8($sp)
	add	$sp,$sp,12
	jr	$ra
	
	
# Procedure inserer_un_descripteur($a0)
# paramètres:
#	$a0 contient l'indice dans le tableau de descripteurs apres lequel on veut inserer un descripteur
#
# cette fonction insere un descripteur après le descripteur indexé par $a0.  En fait, il s'agit de décaler
# par 12 octets le reste du tableau.
#
inserer_un_descripteur:
	add	$sp,$sp,-12
	sw	$ra,8($sp)
	sw	$s0,4($sp)
	sw	$s1,0($sp)

	la	$s1,nb_descript
	lw	$t1,0($s1)	# $t1 = nombre de descripteurs
	sub	$t2,$t1,$a0	# nombre de descripteurs a recopier: nb_descripteurs - $a0
	addi	$t3,$0,12	# $t3 = 12
	la	$s0,descript
	mul	$t1,$t1,$t3
	add	$t1,$s0,$t1	# $t1 = descripteur [nb_descripteurs]
	sub	$t0,$t1,$t3	# $t0 = descripteur[nb_descripteurs-1]
inserer_boucle:
	lw	$t4,0($t0)	# copier le pointeur
	sw	$t4,0($t1)
	lw	$t4,4($t0)	# copier la taille du bloc
	sw	$t4,4($t1)
	lw	$t4,8($t0)	# copier l'état du bloc.
	sw	$t4,8($t1)
	sub	$t1,$t1,$t3	# passer à l'élément précédent
	sub	$t0,$t0,$t3	# passer à l'élément précédent
	addi	$t2,$t2,-1	# nb de descripteurs à recopier = nb descripteurs à recopier - 1
	bne	$t2,$0,inserer_boucle
	
inserer_fin:
	lw	$t1,0($s1)	# incrementer le nombre de descripteurs
	addi	$t1,$t1,1
	sw	$t1,0($s1)
	
	lw	$s1,0($sp)
	lw	$s0,4($sp)
	lw	$ra,8($sp)
	add	$sp,$sp,12
	jr	$ra

# Fonction $v0 = FREE ($a0)
# 
# Cette fonction libère la mémoire dynamique allouée par malloc.
# 	$a0 contient le pointeur sur le bloc mémoire alloué par malloc
# resultat:
# 	$v0 contient 0 si le free a fonctionné et -1 si erreur.

free:	add	$sp,$sp,-12
	sw	$ra,8($sp)
	sw	$s0,4($sp)
	sw	$s1,0($sp)

	jal	cherche_descripteur
	la	$s0,descript
	addi	$t2,$0,12
	mul	$t0,$v0,$t2
	add	$s0,$s0,$t0
	lw	$t0,8($s0)	# etat du descripteur
	# verifier si occupe
	sw	$0,8($s0)
	#recombiner avec les voisins.
	
	lw	$s1,0($sp)
	lw	$s0,4($sp)
	lw	$ra,8($sp)
	add	$sp,$sp,12
	jr	$ra

#
# fonction $v0 = cherche_descripteur ($a0)
#	$a0 contient le pointeur sur le bloc mémoire alloué par malloc
# retourne $v0 = indice du descripteur si trouvé
#              = -1 si non trouvé.
#
cherche_descripteur:
	add	$sp,$sp,-12
	sw	$ra,8($sp)
	sw	$s0,4($sp)
	sw	$s1,0($sp)

	la	$s0,descript
	la	$s1,nb_descript
	lw	$t1,0($s1)	# le nombre de descripteurs 
	add	$t2,$0,$0	# indice de boucle
cherche_descr_boucle:
	beq	$t2,$t1,cherche_descr_non_trouve

	lw	$t0,0($s0)	# $t0 = descript[$t2].pointeur
	beq	$t0,$a0,cherche_descr_trouve
	addi	$t2,$t2,1	# indice de boucle + 1
	addi	$s0,$s0,12	# taille d'un descripteur
	j	cherche_descr_boucle
cherche_descr_trouve:
	add	$v0,$t2,$0
	j	cherche_descr_fin
cherche_descr_non_trouve:
	li	$v0,-1
cherche_descr_fin:
	lw	$s1,0($sp)
	lw	$s0,4($sp)
	lw	$ra,8($sp)
	add	$sp,$sp,12
	jr	$ra
