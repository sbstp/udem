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

struct digit {
    int val;
    struct digit *next;
};

struct num {
    int val;
    int refcount;
};

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
    struct num *val;
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
        struct num *val;
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
};

/* convertit une valeur numérique [0-9] en son caractère */
char val_to_car(char);
/* convertit un caractère ['0'-'9'] en sa valeur numérique */
char car_to_val(char);
/* détermine si le caractère donné est un chiffre */
bool is_digit(char);
/* détermine si le caractère donné est une lettre */
bool is_letter(char);
/* détermine si le caractère donné est un espace */
bool is_whitespace(char);

/* créer un nombre à partir d'une string */
struct num* num_from_str(const char*);
/* opération: additions */
struct num* num_add(struct num*, struct num*);
/* opération: soustraction */
struct num* num_sub(struct num*, struct num*);
/* opération: multiplication */
struct num* num_mul(struct num*, struct num*);
/* vérifie si le nombre est zéro */
bool num_is_zero(struct num*);
/* imprimer le nombre */
void num_print(struct num*);
/* incrémenter le compteur de référence */
void num_incref(struct num*);
/* décrémenter le compteur de référence et libérer la mémoire si nécessaire */
void num_decref(struct num*);

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

/* lire une ligne de stdin */
struct read_line_result read_line();

/* implémentation */

inline char val_to_car(char val) {
    return val + '0';
}

inline char car_to_val(char car) {
    return car - '0';
}

inline bool is_digit(char car) {
    return car >= '0' && car <= '9';
}

inline bool is_letter(char car) {
    return car >= 'a' && car <= 'z';
}

inline bool is_whitespace(char car) {
    return car == ' ' || car == '\t';
}

struct num* num_from_str(const char *text) {
    struct num *n;

    n = malloc(sizeof(struct num));
    if (n == NULL) return NULL;

    n->val = atoi(text);
    n->refcount = 1;
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

struct num* num_add(struct num *a, struct num *b) {
    struct num *n;

    n = malloc(sizeof(struct num));
    if (n == NULL) return NULL;

    n->val = a->val + b->val;
    n->refcount = 1;
    return n;
}

struct num* num_sub(struct num *a, struct num *b) {
    struct num *n;

    n = malloc(sizeof(struct num));
    if (n == NULL) return NULL;

    n->val = a->val - b->val;
    n->refcount = 1;
    return n;
}

struct num* num_mul(struct num *a, struct num *b) {
    struct num *n;

    n = malloc(sizeof(struct num));
    if (n == NULL) return NULL;

    n->val = a->val * b->val;
    n->refcount = 1;
    return n;
}

bool num_is_zero(struct num *n) {
    return n->val == 0;
}

void num_print(struct num *n) {
    printf("%d\n", n->val);
}

void num_incref(struct num *n) {
    n->refcount++;
}

void num_decref(struct num *n) {
    if (--n->refcount <= 0) {
        free(n);
    }
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
    struct ast_node *node, *new, *op1, *op2;
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
    new = NULL;

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

            new = ast_node_assign(tok.text[1], node);
            if (new == NULL) {
                ast_node_free(node);
            }
        } else if (is_letter(car)) {
            /* use */
            if (tok.len > 1) {
                res.err = AST_PARSE_ERR_VARNAME;
                break;
            }
            new = ast_node_use(car);
        } else if (is_digit(car)) {
            /* num */
            /* TODO validate digit */
            new = ast_node_num(tok.text);
        } else if (car == '+' || car == '-' || car == '*') {
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
                    new = ast_node_oper(AST_OPER_KIND_ADD, op1, op2);
                    break;
                case '-':
                    new = ast_node_oper(AST_OPER_KIND_SUB, op1, op2);
                    break;
                case '*':
                    new = ast_node_oper(AST_OPER_KIND_MUL, op1, op2);
                    break;
                default:
                    abort();
            }

            if (new == NULL) {
                ast_node_free(op1);
                ast_node_free(op2);
            }
        } else {
            res.err = AST_PARSE_ERR_TOKEN;
            res.car = car;
            break;
        }

        /* erreur d'allocation */
        if (new == NULL) {
            res.err = AST_PARSE_ERR_ALLOC;
            break;
        }

        /* erreur de réallocation */
        if (!stack_push(nodes, new)) {
            ast_node_free(new);
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
    } else {
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
            ast_node_free(node->assign->val);
            free(node->assign);
            break;
        case AST_NODE_KIND_USE:
            free(node->use);
            break;
        case AST_NODE_KIND_NUM:
            num_decref(node->num->val);
            free(node->num);
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
    struct num *val, *op1, *op2;
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
            num_incref(val);
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

            num_decref(op1);
            num_decref(op2);
            break;
        default:
            abort();
    }

    res.err = INTER_EVAL_ERR_OK;
    res.val = val;
    return res;
}

struct num* inter_get_var(struct inter *vm, char var) {
    struct num *val;

    val = vm->vars[inter_car_to_var(var)];
    if (val != NULL) {
        num_incref(val);
        return val;
    }
    return NULL;
}

void inter_set_var(struct inter *vm, char var, struct num *val) {
    int index = inter_car_to_var(var);
    /* si la variable contient déjà une valeur */
    if (vm->vars[index] != NULL) {
        num_decref(vm->vars[index]);
    }
    num_incref(val);
    vm->vars[index] = val;
}

void inter_print_vars(struct inter *vm) {
    int i;
    for (i = 0; i < 26; i++) {
        if (vm->vars[i] != NULL) {
            printf("%c = %d\n", i + 'a', vm->vars[i]->val);
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

void inter_cleanup(struct inter *vm) {
    int i;
    for (i = 0; i < 26; i++) {
        if (vm->vars[i] != NULL) {
            num_decref(vm->vars[i]);
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

    for (;;) {
        printf("> ");
        rres = read_line();
        /* erreur d'allocation */
        if (rres.err == READ_LINE_ERR_ALLOC) {
            puts("Erreur d'allocation lors de la lecture de la ligne.");
            continue;
        /* EOF atteint */
        } else if (rres.err == READ_LINE_ERR_EOF) {
            break;
        }
        /* aucune erreur */
        len = strlen(rres.line);
        /* si le contenu de le ligne est égal à "vars", on imprime la liste des variables */
        if (strcmp(rres.line, "vars") == 0) {
            inter_print_vars(&vm);
        /* sinon on essaie d'analyser la chaîne de caractères */
        } else if (len > 0) {
            pres = ast_parse(rres.line);

            /* on regarde si le résultat est un erreur ou non */
            if (pres.err == AST_PARSE_ERR_OK) {
                eres = inter_eval(&vm, pres.node);
                /* on regarde si le résultat est un erreur ou non */
                if (eres.err == INTER_EVAL_ERR_OK) {
                    num_print(eres.val);
                    /* on décrémente le nombre retourné */
                    num_decref(eres.val);
                } else {
                    /* si il y a une erreur, on affiche un message */
                    inter_eval_err_print(eres);
                }

                /* on libère l'espace utilisé par l'ASA */
                ast_node_free(pres.node);
            } else {
                /* si il y a une erreur, on affiche un message */
                ast_parse_err_print(pres);
            }
        }
        /* on libère l'espace utilisé par la ligne */
        free(rres.line);
    }

    /* nettoyage final */
    inter_cleanup(&vm);
    return 0;
}
