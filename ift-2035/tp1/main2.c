/*
* IFT-2035: Travail pratique 1
*
* Auteurs:
*   Simon Bernier St-Pierre
*
* "Repository" Git: https://github.com/sbstp/udem/tree/master/ift-2035/tp1
*
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum { false, true } bool;
//Représente un chiffre de 0 à 9
typedef struct figure
{
	unsigned int val : 4;
}Figure;

//Variable globale : contient les chiffres constants 0-9
static Figure *__val[10];

typedef struct digit {
	struct figure *val;
	struct digit *next;
}Digit;

typedef struct num {
	bool isNeg;
	struct digit *first;
}Num;

struct stack {
	int cap;
	int len;
	void** items;
};

struct token {
	size_t len;
	char* text;
};

struct tokenizer {
	const char *src;
	size_t pos;
	size_t len;
	char *buff;
};

enum ast_node_kind {
	AST_NODE_KIND_ASSIGN,
	AST_NODE_KIND_USE,
	AST_NODE_KIND_NUM,
	AST_NODE_KIND_OPER,
};

enum ast_oper_kind {
	AST_OPER_KIND_ADD,
	AST_OPER_KIND_SUB,
	AST_OPER_KIND_MUL,
};

enum ast_parse_err {
	AST_PARSE_ERR_OK,
	AST_PARSE_ERR_ALLOC,
	AST_PARSE_ERR_VARNAME,
	AST_PARSE_ERR_MISSING_VARNAME,
	AST_PARSE_ERR_TOKEN,
	AST_PARSE_ERR_TOO_MANY_EXPR,
	AST_PARSE_ERR_TOO_LITTLE_OPER,
};

struct ast_node_assign {
	char var;
	struct ast_node* val;
};

struct ast_node_use {
	char var;
};

struct ast_node_num {
	Num* val;
};

struct ast_node_oper {
	enum ast_oper_kind kind;
	struct ast_node *op1;
	struct ast_node *op2;
};

struct ast_node {
	enum ast_node_kind kind;
	union {
		struct ast_node_assign *assign;
		struct ast_node_use *use;
		struct ast_node_num *num;
		struct ast_node_oper *oper;
	};
};

struct ast_parse_result {
	enum ast_parse_err err;
	union {
		char car;
		struct ast_node *node;
	};
};

enum inter_eval_err {
	INTER_EVAL_ERR_OK,
	INTER_EVAL_ERR_ALLOC,
	INTER_EVAL_ERR_UNDEF_VAR,
};

struct inter_eval_result {
	enum inter_eval_err err;
	union {
		char var;
		Num* val;
	};
};

struct inter {
	struct num *vars[26];
};

enum read_line_err {
	READ_LINE_ERR_OK,
	READ_LINE_ERR_ALLOC,
	READ_LINE_ERR_EOF,
};

struct read_line_result {
	enum read_line_err err;
	char* line;
	Num *vars[26];
};

/* convertit une valeur numérique [0-9] en son caractère */
char val_to_car(char);
/* convertit un caractère ['0'-'9'] en sa valeur numérique */
char car_to_val(char);
/* détermine si le caractère donné est un chiffre */
bool is_digit(char*);
/* détermine si le caractère donné est une lettre */
bool is_letter(char);
/* détermine si le caractère donné est un espace */
bool is_whitespace(char);

/* créer un nombre à partir d'une string */
Num* num_from_str(const char*);
/*Obtenir le chiffre selon un entier*/
Figure* figure_from_int(int);
/*Obtenir le chiffre selon une chai*/
Figure* figure_from_str(char);
/* opération: additions */
Num* num_add(Num*, Num*);
/* opération: soustraction */
Num* num_sub(struct num*, struct num*);
/* multiplication Num par un digit*/
Num* multiplicationNombreEntier(Num *n, Digit *d, int p);
/* opération: multiplication */
Num* num_mul(struct num*, struct num*);
/* vérifie si le nombre est zéro */
bool num_is_zero(struct num*);
/* imprimer le nombre */
void num_print(struct num*);
/* incrémenter le compteur de référence */
//void num_incref(struct num*);
/* décrémenter le compteur de référence et libérer la mémoire si nécessaire */
//void num_decref(struct num*);
/*libérer Num*/
Num* init_Num(bool, Digit*);
/*Initialise Num*/
void dispose_Num(Num*);
/*libérer Num*/
Digit* init_Digit(Figure*, Digit*);
/*Initialise Digit*/
void dispose_Digit(Digit*);

/* créer un nouvea stack avec la capacité donnée */
struct stack* stack_new(int cap);
/* ajouter un élément au tas */
bool stack_push(struct stack*, void*);
/* obtenir l'élément au dessus du tas */
void* stack_pop(struct stack*);
/* libérer la mémoire utilisée par le tas */
void stack_free(struct stack*);

/* créer un nouveau tokenizer à partir de la source */
struct tokenizer* tokenizer_new(const char*);
/* obtenir le prochain token */
bool tokenizer_next(struct tokenizer*, struct token*);
/* libérer l'espace utilisé par le tokenizer */
void tokenizer_free(struct tokenizer*);

/* créer un noeud de type assignation */
struct ast_node* ast_node_assign(char, struct ast_node*);
/* créer un noeud de type utilisation de variable */
struct ast_node* ast_node_use(char);
/* créer un noeud de type nombre */
struct ast_node* ast_node_num(const char*);
/* créer un noeud de type opérateur */
struct ast_node* ast_node_oper(enum ast_oper_kind, struct ast_node*, struct ast_node*);
/* analyser la chaîne de caractères et construire l'ASA */
struct ast_parse_result ast_parse(const char*);
/* imprimer un message approprié pour l'erreur */
void ast_parse_err_print(struct ast_parse_result);
/* libérer la mémoire utilisée par l'ASA */
void ast_node_free(struct ast_node*);

/* convertit un nom de variable en index */
int inter_car_to_var(char);
/* évaluer l'ASA et retourner la valeur de l'expression */
struct inter_eval_result inter_eval(struct inter*, struct ast_node*);
/* obtenir la valeur d'une variable */
struct num* inter_get_var(struct inter *vm, char var);
/* modifier la valeur d'une variable */
void inter_set_var(struct inter *vm, char var, struct num*);
/* imprimer la valeur de toutes les variables */
void inter_print_vars(struct inter*);
/* imprimer un message approprié pour l'erreur */
void inter_eval_err_print(struct inter_eval_result res);
/* libérer l'espace utilisé par les variables */
void inter_cleanup(struct inter*);
/*libérer les chiffres constants*/
void figures_cleanup();

/* lire une ligne de stdin */
struct read_line_result read_line();

/* implémentation */

inline char val_to_car(char val) {
	return val + '0';
}

inline char car_to_val(char car) {
	return car - '0';
}

inline bool is_digit(char* s) {
	int len = strlen(s);
	int i = 0;
	if (len < 1) return false;

	if (s[0] == '-')
		if (len < 2)
			return false;
		else
			i++;

	for (; i < len; i++)
		if (s[i] < '0' || s[i] > '9')
			return false;
	return true;
}

inline bool is_letter(char car) {
	return car >= 'a' && car <= 'z';
}

inline bool is_whitespace(char car) {
	return car == ' ' || car == '\t';
}
Figure* figure_from_int(int val) {
	if (__val[val] == NULL)
	{
		Figure *f = malloc(sizeof(Figure));
		if (f == NULL)
			return NULL;
		f->val = val;
		__val[val] = f;
	}
	return __val[val];
}
Figure* figure_from_str(char c) {
	return figure_from_int(c - '0');
}
Num* num_from_str(const char *text) {
	int i = strlen(text) - 1;
	int end = 0;
	bool isNeg = false;
	if (text[0] == '-')
	{
		isNeg = true;
		end++;
	}
	Num* n = init_Num(isNeg, NULL);
	Digit *prev, *d;
	//initialiser le premier Digit
	Figure *f = figure_from_str(text[i]);
	d = prev = init_Digit(f, NULL);
	n->first = d;
	i--;
	//initialiser le reste du Num, si necessaire
	for (; i >= end; i--) {
		f = figure_from_str(text[i]);
		d = init_Digit(f, NULL);
		prev->next = d;
		prev = d;
	}
	return n;
	// int len, i, lo;
	// struct num *n;
	// struct digit *p, *d;
	//
	// len = strlen(text);
	// p = NULL;
	//
	// n = malloc(sizeof(struct num));
	// if (n == NULL) return NULL;
	//
	// /* si le nombre débute par '-', il est négatif */
	// n->pos = text[0] != '-';
	// n->len = 0;
	// /* si il y a un signe '-', on arrête de copier avant 1 caractère plus tôt */
	// lo = !n->pos;
	//
	// for (i = len - 1; i >= lo; i--) {
	//     d = malloc(sizeof(struct digit));
	//     /* si on arrive pas à allouer, on détruit tout ce qui a été alloué auparavant */
	//     if (d == NULL) {
	//         num_free(n);
	//         return NULL;
	//     }
	//
	//     d->val = car_to_val(text[i]);
	//     n->len++;
	//     if (p == NULL)
	//         n->first = p = d;
	//     else
	//         p->next = d;
	//     p = d;
	// }
	//
	// return n;
}
static int dNum = 0;
static int dDigit = 0;
Num* init_Num(bool isNeg, Digit* first) {
	Num* n = malloc(sizeof(Num));
	if (n == NULL)
	{
		// TODO : Error Malloc
	}
	n->isNeg = isNeg;
	n->first = first;
	dNum++;
	return n;
}
void dispose_Num(Num* n) {
	Digit *d = n->first, *cur = NULL;
	while (d != NULL) {
		cur = d->next;
		dispose_Digit(d);
		d = cur;
	}
	free(n);
	dNum--;
}
Digit* init_Digit(Figure* f, Digit* next) {
	Digit* d = malloc(sizeof(Digit));
	if (d == NULL)
	{
		// TODO : Error Malloc
	}
	d->val = f;
	d->next = next;
	dDigit++;
	return d;
}
void dispose_Digit(Digit* d) {
	//Ne jamais libérer une figure, elles seront libérer à la fin.
	//Le Num est responsable de libérer la liste de Digit
	free(d);
	dDigit--;
}

Num* num_add(Num* n1, Num* n2) {
	//		   n2
	//	    | 0 | 1 |
	// n1  0| A | S	|  si A doit etre une addition
	//	   1| S | A |  si S doit etre une soustraction
	if (n1->isNeg != n2->isNeg)
	{
		n2->isNeg = ~n2->isNeg;
		return num_sub(n1, n2);
	}

	Num* resultat = init_Num(n1->isNeg & n2->isNeg, NULL);
	int surplus = 0;
	int k = 0;
	int r = 0;
	Digit *d1 = n1->first;
	Digit *d2 = n2->first;
	Digit *cur = NULL, *d = NULL;
	for (; d1 != NULL && d2 != NULL; k++) {
		r = d1->val->val + d2->val->val + surplus;
		d = init_Digit(figure_from_int(r % 10), NULL);
		surplus = r / 10;

		if (cur == NULL) resultat->first = cur = d;
		else cur->next = d;
		cur = d;
		d1 = d1->next;
		d2 = d2->next;
	}
	if (d1 != NULL)
	{
		while (d1 != NULL)
		{
			r = d1->val->val + surplus;
			d = init_Digit(figure_from_int(r % 10), NULL);
			surplus = r / 10;
			cur->next = d;
			cur = d;
			d1 = d1->next;
		}
	}
	else if (d2 != NULL)
	{
		while (d2 != NULL)
		{
			r = d2->val->val + surplus;
			d = init_Digit(figure_from_int(r % 10), NULL);
			surplus = r / 10;
			cur->next = d;;
			cur = d;
			d2 = d2->next;
		}
	}
	if (surplus > 0)
	{
		d = init_Digit(figure_from_int(surplus), NULL);
		cur->next = d;
	}
	return resultat;
}

Num* num_sub(Num *n1, Num *n2) {
	return NULL; //TODO : num_sub
}

struct num* num_mul(struct num *a, struct num *b) {
	return NULL; //TODO : num_mul
}

//bool num_is_zero(struct num *n) {
//    return false; //TODO : num_is_zero
//}

void num_print(Num *n) {
	char *line = NULL, *tmp = NULL;
	size_t size = 0, index = 0, buffer_size = 20;
	char c = '\0';
	Digit *d = n->first;

	while (d != NULL) {
		c = d->val->val + '0';

		/* Aggrandir le tableau si necessaire */
		if (size <= index) {
			size += buffer_size;
			tmp = realloc(line, size);
			if (!tmp) {
				free(line);
				line = NULL;
				break;
			}
			line = tmp;
		}

		/* Actually store the thing. */
		line[index++] = c;
		d = d->next;
	}
	line[index++] = '\0';

	for (int i = strlen(line) - 1; i >= 0; i--)
		printf("%c", line[i]);
}

struct stack* stack_new(int cap) {
	struct stack *s;

	s = malloc(sizeof(struct stack));
	if (s == NULL) return NULL;

	s->cap = cap;
	s->len = 0;

	s->items = malloc(sizeof(void*) * cap);
	if (s->items == NULL) {
		free(s);
		return NULL;
	}

	return s;
}

bool stack_push(struct stack *s, void *item) {
	int newcap;
	void** items;

	if (s->len >= s->cap) {
		newcap = s->cap * 2;
		items = realloc(s->items, newcap);
		if (items == NULL) return false;
		s->cap = newcap;
		s->items = items;
	}

	s->items[s->len++] = item;
	return true;
}

void* stack_pop(struct stack *s) {
	if (s->len > 0) {
		return s->items[--s->len];
	}
	return NULL;
}

void stack_free(struct stack *s) {
	free(s->items);
	free(s);
}

struct tokenizer* tokenizer_new(const char *src) {
	struct tokenizer *tkzer;

	tkzer = malloc(sizeof(struct tokenizer));
	if (tkzer == NULL) return NULL;

	tkzer->pos = 0;
	tkzer->len = strlen(src);
	tkzer->src = src;
	/* en créant un charbuff de la taille de src, on s'assure
	* qu'il n'y aura pas de réallocation dans tokenizer_next. */
	tkzer->buff = malloc(sizeof(char) * tkzer->len);
	if (tkzer->buff == NULL) {
		free(tkzer);
		return NULL;
	}

	return tkzer;
}

bool tokenizer_next(struct tokenizer* tkzer, struct token *tok) {
	char car;
	bool found_tok;
	int idx = 0;

	if (tkzer->pos >= tkzer->len) return false;

	found_tok = false;
	do {
		car = tkzer->src[tkzer->pos++];
		if (car == '\0') break;
		if (is_whitespace(car)) {
			if (found_tok) break;
			else continue;
		}
		found_tok = true;
		tkzer->buff[idx++] = car;
	} while (true);
	tkzer->buff[idx] = '\0';

	if (!found_tok) return false;

	tok->len = idx;
	tok->text = tkzer->buff;

	return true;
}

void tokenizer_free(struct tokenizer *tkzer) {
	free(tkzer->buff);
	free(tkzer);
}

struct ast_node* ast_node_assign(char var, struct ast_node *val) {
	struct ast_node *node;

	node = malloc(sizeof(struct ast_node));
	if (node == NULL) return NULL;

	node->assign = malloc(sizeof(struct ast_node_assign));
	if (node->assign == NULL) {
		free(node);
		return NULL;
	}

	node->kind = AST_NODE_KIND_ASSIGN;
	node->assign->var = var;
	node->assign->val = val;

	return node;
}

struct ast_node* ast_node_use(char var) {
	struct ast_node *node;

	node = malloc(sizeof(struct ast_node));
	if (node == NULL) return NULL;

	node->use = malloc(sizeof(struct ast_node_use));
	if (node->use == NULL) {
		free(node);
		return NULL;
	}

	node->kind = AST_NODE_KIND_USE;
	node->use->var = var;

	return node;
}

struct ast_node* ast_node_num(const char* source) {
	struct ast_node *node;

	node = malloc(sizeof(struct ast_node));
	if (node == NULL) return NULL;

	node->num = malloc(sizeof(struct ast_node_num));
	if (node->num == NULL) {
		free(node);
		return NULL;
	}

	node->num->val = num_from_str(source);
	if (node->num->val == NULL) {
		free(node->num);
		free(node);
		return NULL;
	}

	node->kind = AST_NODE_KIND_NUM;

	return node;
}

struct ast_node* ast_node_oper(enum ast_oper_kind kind, struct ast_node* op1, struct ast_node* op2) {
	struct ast_node *node;

	node = malloc(sizeof(struct ast_node));
	if (node == NULL) return NULL;

	node->oper = malloc(sizeof(struct ast_node_oper));
	if (node->oper == NULL) {
		free(node);
		return NULL;
	}

	node->kind = AST_NODE_KIND_OPER;
	node->oper->kind = kind;
	node->oper->op1 = op1;
	node->oper->op2 = op2;

	return node;
}

struct ast_parse_result ast_parse(const char* text) {
	char car;
	struct ast_parse_result res;
	struct ast_node *node, *n, *op1, *op2;
	struct stack *nodes;
	struct tokenizer *tkzer;
	struct token tok;

	nodes = stack_new(8);
	if (nodes == NULL) {
		res.err = AST_PARSE_ERR_ALLOC;
		return res;
	}

	tkzer = tokenizer_new(text);
	if (tkzer == NULL) {
		stack_free(nodes);
		res.err = AST_PARSE_ERR_ALLOC;
		return res;
	}

	res.err = AST_PARSE_ERR_OK;
	n = NULL;

	while (tokenizer_next(tkzer, &tok)) {
		car = tok.text[0];
		if (car == '=') {
			/* assign */
			node = stack_pop(nodes);

			/* il n'y a rien à assigner */
			if (node == NULL) {
				res.err = AST_PARSE_ERR_TOO_LITTLE_OPER;
				break;
			}
			/* nom de variable manquant */
			if (tok.len == 1) {
				ast_node_free(node);
				res.err = AST_PARSE_ERR_MISSING_VARNAME;
				break;
			}
			/* le nom de variable est trop long */
			if (tok.len > 2) {
				ast_node_free(node);
				res.err = AST_PARSE_ERR_VARNAME;
				break;
			}

			n = ast_node_assign(tok.text[1], node);
			if (n == NULL) {
				ast_node_free(node);
			}
		}
		else if (is_letter(car)) {
			/* use */
			if (tok.len > 1) {
				res.err = AST_PARSE_ERR_VARNAME;
				break;
			}
			n = ast_node_use(car);
		}
		else if (is_digit(tok.text)) {
			/* num */
			n = ast_node_num(tok.text);
		}
		else if (car == '+' || car == '-' || car == '*') {
			/* obtenir la deuxieme opérande, erreur si il n'y en a pas */
			op2 = stack_pop(nodes);
			if (op2 == NULL) {
				res.err = AST_PARSE_ERR_TOO_LITTLE_OPER;
				break;
			}
			/* obtenir la première opérande, erreur si il n'y en a pas */
			op1 = stack_pop(nodes);
			if (op1 == NULL) {
				ast_node_free(op2);
				res.err = AST_PARSE_ERR_TOO_LITTLE_OPER;
				break;
			}
			/* détecter l'opérateur */
			switch (car) {
			case '+':
				n = ast_node_oper(AST_OPER_KIND_ADD, op1, op2);
				break;
			case '-':
				n = ast_node_oper(AST_OPER_KIND_SUB, op1, op2);
				break;
			case '*':
				n = ast_node_oper(AST_OPER_KIND_MUL, op1, op2);
				break;
			default:
				abort();
			}

			if (n == NULL) {
				ast_node_free(op1);
				ast_node_free(op2);
			}
		}
		else {
			res.err = AST_PARSE_ERR_TOKEN;
			res.car = car;
			break;
		}

		/* erreur d'allocation */
		if (n == NULL) {
			res.err = AST_PARSE_ERR_ALLOC;
			break;
		}

		/* erreur de réallocation */
		if (!stack_push(nodes, n)) {
			ast_node_free(n);
			res.err = AST_PARSE_ERR_ALLOC;
			break;
		}
	}

	/* si il reste plus qu'un item dans le stack, c'est qu'il y a plusieurs expressions */
	if (res.err == AST_PARSE_ERR_OK && nodes->len > 1) {
		res.err = AST_PARSE_ERR_TOO_MANY_EXPR;
	}

	/* pas d'erreurs */
	if (res.err == AST_PARSE_ERR_OK) {
		res.node = stack_pop(nodes);
	}
	else {
		/* si il y a eu une erreur, on libère les noeuds restants */
		while ((node = stack_pop(nodes)) != NULL) {
			ast_node_free(node);
		}
	}

	stack_free(nodes);
	tokenizer_free(tkzer);
	return res;
}

void ast_parse_err_print(struct ast_parse_result res) {
	switch (res.err) {
	case AST_PARSE_ERR_OK:
		break;
	case AST_PARSE_ERR_ALLOC:
		puts("Impossible d'allouer la mémoire nécessaire.");
		break;
	case AST_PARSE_ERR_VARNAME:
		puts("Les noms de variables doivent être d'un seul caractère entre a et z.");
		break;
	case AST_PARSE_ERR_MISSING_VARNAME:
		puts("Nom de variable manquant dans l'assignation.");
		break;
	case AST_PARSE_ERR_TOKEN:
		printf("La ligne contient un caractère invalide: %c.\n", res.car);
		break;
	case AST_PARSE_ERR_TOO_MANY_EXPR:
		puts("La ligne entrée contient plus qu'une expression.");
		break;
	case AST_PARSE_ERR_TOO_LITTLE_OPER:
		puts("L'opérateur nécessite plus d'opérandes.");
		break;
	default:
		abort();
	}
}

void ast_node_free(struct ast_node *node) {
	switch (node->kind) {
	case AST_NODE_KIND_ASSIGN:
		//Il ne faut pas libérer le contenu de l'asssignation
		//puisque nous ne voulons pas libérer la variable que nous venons juste d'assigner.
		free(node->assign);
		break;
	case AST_NODE_KIND_USE:
		free(node->use);
		break;
	case AST_NODE_KIND_NUM:
		dispose_Num(node->num->val);
		break;
	case AST_NODE_KIND_OPER:
		ast_node_free(node->oper->op1);
		ast_node_free(node->oper->op2);
		free(node->oper);
		break;
	default:
		abort();
	}
	free(node);
}

inline int inter_car_to_var(char var) {
	return var - 'a';
}

struct inter_eval_result inter_eval(struct inter *vm, struct ast_node *node) {
	Num *val, *op1, *op2;
	struct inter_eval_result res;

	switch (node->kind) {
	case AST_NODE_KIND_ASSIGN:
		res = inter_eval(vm, node->assign->val);
		if (res.err != INTER_EVAL_ERR_OK) return res;
		inter_set_var(vm, node->assign->var, res.val);
		val = res.val;
		break;
	case AST_NODE_KIND_USE:
		val = inter_get_var(vm, node->assign->var);
		if (val == NULL) {
			res.err = INTER_EVAL_ERR_UNDEF_VAR;
			res.var = node->assign->var;
			return res;
		}
		break;
	case AST_NODE_KIND_NUM:
		val = node->num->val;
		break;
	case AST_NODE_KIND_OPER:
		res = inter_eval(vm, node->oper->op1);
		if (res.err != INTER_EVAL_ERR_OK) return res;
		op1 = res.val;

		res = inter_eval(vm, node->oper->op2);
		if (res.err != INTER_EVAL_ERR_OK) return res;
		op2 = res.val;

		switch (node->oper->kind) {
		case AST_OPER_KIND_ADD:
			val = num_add(op1, op2);
			break;
		case AST_OPER_KIND_SUB:
			val = num_sub(op1, op2);
			break;
		case AST_OPER_KIND_MUL:
			val = num_mul(op1, op2);
			break;
		default:
			abort();
		}

		/* erreur dans l'allocation du nombre */
		if (val == NULL) {
			res.err = INTER_EVAL_ERR_ALLOC;
			return res;
		}
		break;
	default:
		abort();
	}

	res.err = INTER_EVAL_ERR_OK;
	res.val = val;
	return res;
}

Num* inter_get_var(struct inter *vm, char var) {
	Num *val;

	val = vm->vars[inter_car_to_var(var)];
	if (val != NULL) {

		return val;
	}
	return NULL;
}

void inter_set_var(struct inter *vm, char var, Num *val) {
	int index = inter_car_to_var(var);
	/* si la variable contient déjà une valeur */
	if (vm->vars[index] != NULL) {
		dispose_Num(vm->vars[index]);
	}
	vm->vars[index] = val;
}

void inter_print_vars(struct inter *vm) {
	int i;
	for (i = 0; i < 26; i++) {
		if (vm->vars[i] != NULL) {
			num_print(vm->vars[i]);
			printf(" = %d\n", i + 'a');
		}
	}
}

void inter_eval_err_print(struct inter_eval_result res) {
	switch (res.err) {
	case INTER_EVAL_ERR_OK:
		break;
	case INTER_EVAL_ERR_ALLOC:

		puts("Erreur d'allocation lors de l'évaluation de l'ASA.");
		break;
	case INTER_EVAL_ERR_UNDEF_VAR:
		printf("La variable '%c' n'a pas de valeur.\n", res.var);
		break;
	default:
		abort();
	}
}

void figures_cleanup() {
	for (int i = 0; i < 10; i++)
	{
		if (__val[i] != NULL)
		{
			free(__val[i]);
			__val[i] = NULL;
		}
	}
}

void inter_cleanup(struct inter *vm) {
	int i;
	for (i = 0; i < 26; i++) {
		if (vm->vars[i] != NULL) {
			dispose_Num(vm->vars[i]);
			vm->vars[i] = NULL;
		}
	}
}

struct read_line_result read_line() {
	int len = 0;
	int cap = 10;
	char *buff, *tmp;
	int car;
	struct read_line_result res;

	buff = malloc(cap + 1);
	if (buff == NULL) {
		res.err = READ_LINE_ERR_ALLOC;
		return res;
	}

	while ((car = getchar()) != EOF) {
		if (car == '\n') {
			buff[len] = '\0';
			res.err = READ_LINE_ERR_OK;
			res.line = buff;
			return res;
		}

		if (len >= cap) {
			cap *= 2;
			tmp = realloc(buff, cap + 1);
			if (tmp == NULL) {
				free(buff);
				res.err = READ_LINE_ERR_ALLOC;
				return res;
			}
			buff = tmp;
		}
		buff[len++] = car;
	}

	free(buff);
	res.err = READ_LINE_ERR_EOF;
	return res;
}

int main(int argc, char **argv) {
	struct inter vm;
	struct read_line_result rres;
	struct ast_parse_result pres;
	struct inter_eval_result eres;
	int len;

	memset(&vm, 0, sizeof(struct inter));
	printf("> ");
	for (;;) {
		rres = read_line();
		/* erreur d'allocation */
		if (rres.err == READ_LINE_ERR_ALLOC) {
			puts("Erreur d'allocation lors de la lecture de la ligne.");
			continue;
			/* EOF atteint */
		}
		else if (rres.err == READ_LINE_ERR_EOF) {
			break;
		}
		/* aucune erreur */
		len = strlen(rres.line);
		/* si le contenu de le ligne est égal à "vars", on imprime la liste des variables */
		if (strcmp(rres.line, "vars") == 0) {
			inter_print_vars(&vm);
			/* sinon on essaie d'analyser la chaîne de caractères */
		}
		else if (len > 0) {
			pres = ast_parse(rres.line);

			/* on regarde si le résultat est un erreur ou non */
			if (pres.err == AST_PARSE_ERR_OK) {
				eres = inter_eval(&vm, pres.node);
				/* on regarde si le résultat est un erreur ou non */
				if (eres.err == INTER_EVAL_ERR_OK) {
					num_print(eres.val);
					dispose_Num(eres.val);
				}
				else {
					/* si il y a une erreur, on affiche un message */
					inter_eval_err_print(eres);
				}

				/* on libère l'espace utilisé par l'ASA */
				ast_node_free(pres.node);
			}
			else {
				/* si il y a une erreur, on affiche un message */
				ast_parse_err_print(pres);
			}
		}
		/* on libère l'espace utilisé par la ligne */
		free(rres.line);
		printf("\n NumRef = %d, DigitRef = %d", dNum, dDigit);
		printf("\n> ");
	}

	/* nettoyage final */
	inter_cleanup(&vm);
	figures_cleanup();
	return 0;
}
