#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum { false, true } bool;

struct digit {
    int val;
    struct digit *next;
};

struct num {
    bool pos;
    int len;
    struct digit *first;
};

struct charbuff {
    int cap;
    int len;
    char* buff;
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
    const char* src;
    size_t pos;
    size_t len;
    struct charbuff* cb;
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
    int val; /* TODO: bignum */
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
    struct ast_node *node;
};

struct inter {
    int vars[26];
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
/* créer un clone complet du nombre */
struct num* num_clone(const struct num*);
/* formatter le nombre en string */
char* num_to_str(const struct num*);
/* libérer la mémoire utilisée par le nombre */
void num_free(struct num*);

/* créer un nouveau charbuff avec la capacitée donnée */
struct charbuff* charbuff_new(int cap);
/* ajouter un caractère et redimensionner au besoin */
bool charbuff_push(struct charbuff*, char);
/* disposer du texte contenu, mais sauvegarder l'espace mémoire  */
void charbuff_clear(struct charbuff*);
/* libérer la mémoire utilisé par le tampon */
void charbuff_free(struct charbuff*);

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
/* obtenir un approprié message pour l'erreur donnée */
const char* ast_parse_err_msg(enum ast_parse_err);
/* libérer la mémoire utilisée par l'ASA */
void ast_node_free(struct ast_node*);

/* évaluer l'ASA et retourner la valeur de l'expression */
int inter_eval(struct inter*, struct ast_node*);
/* imprimer la valeur de toutes les variables */
void inter_print_vars(struct inter*);

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
    int len, i, lo;
    struct num *n;
    struct digit *p, *d;

    len = strlen(text);
    p = NULL;

    n = malloc(sizeof(struct num));
    if (n == NULL) return NULL;

    /* si le nombre débute par '-', il est négatif */
    n->pos = text[0] != '-';
    n->len = 0;
    /* si il y a un signe '-', on arrête de copier avant 1 caractère plus tôt */
    lo = !n->pos;

    for (i = len - 1; i >= lo; i--) {
        d = malloc(sizeof(struct digit));
        /* si on arrive pas à allouer, on détruit tout ce qui a été alloué auparavant */
        if (d == NULL) {
            num_free(n);
            return NULL;
        }

        d->val = car_to_val(text[i]);
        n->len++;
        if (p == NULL)
            n->first = p = d;
        else
            p->next = d;
        p = d;
    }

    return n;
}

struct num* num_clone(const struct num *n) {
    struct num *c;
    struct digit *d, *prev, *new;

    c = malloc(sizeof(struct num));
    if (c == NULL) return NULL;

    c->pos = n->pos;
    c->len = n->len;

    d = n->first;
    prev = NULL;
    while (d != NULL) {
        new = malloc(sizeof(struct digit));
        if (new == NULL) {
            num_free(c);
            return NULL;
        }

        new->val = d->val;
        /* si c'est la première itération, on attache new à c->first */
        if (prev == NULL)
            c->first = new;
        /* sinon on attache new, au précédent */
        else
            prev->next = new;

        prev = new;
        d = d->next;
    }

    return c;
}

char* num_to_str(const struct num *n) {
    int len, i;
    char *text;
    struct digit *d;

    len = n->len + 1;   // \0
    if (!n->pos) len++; // négatif

    text = malloc(sizeof(char) * len);
    if (text == NULL) return NULL;

    i = len - 2;
    d = n->first;
    while (d != NULL) {
        text[i--] = val_to_car(d->val);
        d = d->next;
    }

    text[len - 1] = '\0';
    if (!n->pos) {
        text[0] = '-';
    }

    return text;
}

void num_free(struct num *n) {
    struct digit *d, *t;

    d = n->first;
    while (d != NULL) {
        t = d->next;
        free(d);
        d = t;
    }

    free(n);
}

struct charbuff* charbuff_new(int cap) {
    struct charbuff *cb;

    cb = malloc(sizeof(struct charbuff));
    if (cb == NULL) return NULL;

    cb->cap = cap;
    cb->len = 0;

    cb->buff = malloc(sizeof(char) * cap + 1);
    if (cb->buff == NULL) {
        free(cb);
        return NULL;
    }

    return cb;
}

bool charbuff_push(struct charbuff *cb, char c) {
    int newcap;
    char* buff;

    if (cb->len >= cb->cap) {
        newcap = cb->cap * 2;
        buff = realloc(cb->buff, sizeof(char) * newcap + 1);
        if (buff == NULL) {
            charbuff_free(cb); /* TODO: don't free */
            return false;
        }
        cb->cap = newcap;
        cb->buff = buff;
    }

    cb->buff[cb->len++] = c;
    cb->buff[cb->len] = '\0';

    return true;
}

void charbuff_clear(struct charbuff *cb) {
    cb->buff[0] = '\0';
    cb->len = 0;
}

void charbuff_free(struct charbuff *cb) {
    free(cb->buff);
    free(cb);
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
    tkzer->pos = 0;
    tkzer->len = strlen(src);
    tkzer->src = src;
    tkzer->cb = charbuff_new(16);

    return tkzer;
}

bool tokenizer_next(struct tokenizer* tkzer, struct token *tok) {
    char car;
    bool found_tok;

    if (tkzer->pos >= tkzer->len) return false;

    found_tok = false;
    charbuff_clear(tkzer->cb);
    do {
        car = tkzer->src[tkzer->pos++];
        if (car == '\0') break;
        if (is_whitespace(car)) {
            if (found_tok) break;
            else continue;
        }
        found_tok = true;
        charbuff_push(tkzer->cb, car);
    } while (true);

    if (!found_tok) return false;

    tok->len = tkzer->cb->len;
    tok->text = tkzer->cb->buff;

    return true;
}

void tokenizer_free(struct tokenizer *tkzer) {
    charbuff_free(tkzer->cb);
    free(tkzer);
}

struct ast_node* ast_node_assign(char var, struct ast_node *val) {
    struct ast_node *node;

    node = malloc(sizeof(struct ast_node));
    node->kind = AST_NODE_KIND_ASSIGN;
    node->assign = malloc(sizeof(struct ast_node_assign));
    node->assign->var = var;
    node->assign->val = val;

    return node;
}

struct ast_node* ast_node_use(char var) {
    struct ast_node *node;

    node = malloc(sizeof(struct ast_node));
    node->kind = AST_NODE_KIND_USE;
    node->use = malloc(sizeof(struct ast_node_use));
    node->use->var = var;

    return node;
}

struct ast_node* ast_node_num(const char* source) {
    struct ast_node *node;

    node = malloc(sizeof(struct ast_node));
    node->kind = AST_NODE_KIND_NUM;
    node->use = malloc(sizeof(struct ast_node));
    node->num->val = atoi(source);

    return node;
}

struct ast_node* ast_node_oper(enum ast_oper_kind kind, struct ast_node* op1, struct ast_node* op2) {
    struct ast_node *node;

    node = malloc(sizeof(struct ast_node));
    node->kind = AST_NODE_KIND_OPER;
    node->oper = malloc(sizeof(struct ast_node_oper));
    node->oper->kind = kind;
    node->oper->op1 = op1;
    node->oper->op2 = op2;

    return node;
}

struct ast_parse_result ast_parse(const char* text) {
    char car;
    enum ast_oper_kind okind;
    struct ast_parse_result result;
    struct ast_node *node, *new, *op1, *op2;
    struct stack *nodes;
    struct tokenizer *tkzer;
    struct token tok;

    /* TODO: malloc errors */
    nodes = stack_new(4);
    tkzer = tokenizer_new(text);
    result.err = AST_PARSE_ERR_OK;

    while (tokenizer_next(tkzer, &tok)) {
        car = tok.text[0];
        if (car == '=') {
            /* assign */
            node = stack_pop(nodes);

            /* il n'y a rien à assigner */
            if (node == NULL) {
                result.err = AST_PARSE_ERR_TOO_LITTLE_OPER;
                break;
            }
            /* nom de variable manquant */
            if (tok.len == 1) {
                result.err = AST_PARSE_ERR_MISSING_VARNAME;
                break;
            }
            /* le nom de variable est trop long */
            if (tok.len > 2) {
                result.err = AST_PARSE_ERR_VARNAME;
                break;
            }

            new = ast_node_assign(tok.text[1], node);
            stack_push(nodes, new);
        } else if (is_letter(car)) {
            /* use */
            if (tok.len > 1) {
                result.err = AST_PARSE_ERR_VARNAME;
                break;
            }
            new = ast_node_use(car);
            stack_push(nodes, new);
        } else if (is_digit(car)) {
            /* num */
            /* TODO validate digit */
            new = ast_node_num(tok.text);
            stack_push(nodes, new);
        } else if (car == '+' || car == '-' || car == '*') {
            /* obtenir la deuxieme opérande, erreur si il n'y en a pas */
            op2 = stack_pop(nodes);
            if (op2 == NULL) {
                result.err = AST_PARSE_ERR_TOO_LITTLE_OPER;
                break;
            }
            /* obtenir la première opérande, erreur si il n'y en a pas */
            op1 = stack_pop(nodes);
            if (op1 == NULL) {
                free(op2);
                result.err = AST_PARSE_ERR_TOO_LITTLE_OPER;
                break;
            }
            /* détecter l'opérateur */
            switch (car) {
                case '+':
                    okind = AST_OPER_KIND_ADD;
                    break;
                case '-':
                    okind = AST_OPER_KIND_SUB;
                    break;
                case '*':
                    okind = AST_OPER_KIND_MUL;
                    break;
            }

            new = ast_node_oper(okind, op1, op2);
            stack_push(nodes, new);
        } else {
            result.err = AST_PARSE_ERR_TOKEN;
            break;
        }
    }

    /* si il reste plus qu'un item dans le stack, c'est qu'il y a plusieurs expressions */
    if (nodes->len > 1) {
        result.err = AST_PARSE_ERR_TOO_MANY_EXPR;
    }

    /* pas d'erreurs */
    if (result.err == AST_PARSE_ERR_OK) {
        result.node = stack_pop(nodes);
    } else {
        /* si il y a eu une erreur, on libère les noeuds restants */
        while ((node = stack_pop(nodes)) != NULL) {
            ast_node_free(node);
        }
    }

    stack_free(nodes);
    tokenizer_free(tkzer);
    return result;
}

const char* ast_parse_err_msg(enum ast_parse_err err) {
    switch (err) {
        case AST_PARSE_ERR_OK:
            return NULL;
        case AST_PARSE_ERR_ALLOC:
            return "Impossible d'allouer la mémoire nécessaire.";
        case AST_PARSE_ERR_VARNAME:
            return "Les noms de variables doivent être d'un seul caractère entre a et z.";
        case AST_PARSE_ERR_MISSING_VARNAME:
            return "Nom de variable manquant dans l'assignation.";
        case AST_PARSE_ERR_TOKEN:
            return "La ligne contient un caractère invalide.";
        case AST_PARSE_ERR_TOO_MANY_EXPR:
            return "La ligne entrée contient plus qu'une expression.";
        case AST_PARSE_ERR_TOO_LITTLE_OPER:
            return "L'opérateur nécessite plus d'opérandes.";
    }

    return NULL;
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
            free(node->num);
            break;
        case AST_NODE_KIND_OPER:
            ast_node_free(node->oper->op1);
            ast_node_free(node->oper->op2);
            free(node->oper);
            break;
    }
    free(node);
}

int inter_eval(struct inter *vm, struct ast_node *node) {
    int val;

    switch (node->kind) {
        case AST_NODE_KIND_ASSIGN:
            val = inter_eval(vm, node->assign->val);
            vm->vars[node->assign->var - 'a'] = val;
            return val;
        case AST_NODE_KIND_USE:
            return vm->vars[node->use->var - 'a'];
        case AST_NODE_KIND_NUM:
            return node->num->val;
        case AST_NODE_KIND_OPER:
            switch (node->oper->kind) {
                // TODO: use big num
                case AST_OPER_KIND_ADD:
                    return inter_eval(vm, node->oper->op1) + inter_eval(vm, node->oper->op2);
                case AST_OPER_KIND_SUB:
                    return inter_eval(vm, node->oper->op1) - inter_eval(vm, node->oper->op2);
                case AST_OPER_KIND_MUL:
                    return inter_eval(vm, node->oper->op1) * inter_eval(vm, node->oper->op2);
            }
    }

    return 0;
}

void inter_print_vars(struct inter *vm) {
    int i;
    for (i = 0; i < 26; i++) {
        printf("%c = %d\n", i + 'a', vm->vars[i]);
    }
}

int main(int argc, char **argv) {
    int val, car;
    const char *msg;
    struct inter vm;
    struct charbuff* cb;
    struct ast_parse_result result;

    memset(&vm, 0, sizeof(struct inter));
    cb = charbuff_new(32);

    printf("> ");
    while ((car = getchar()) != EOF) {
        if (car == '\r') continue;
        if (car == '\n') {
            if (cb->len > 0) {
                result = ast_parse(cb->buff);

                if (result.err == AST_PARSE_ERR_OK) {
                    val = inter_eval(&vm, result.node);
                    ast_node_free(result.node);
                    printf("%d\n", val);
                } else {
                    msg = ast_parse_err_msg(result.err);
                    if (msg != NULL) printf("%s\n", msg);
                }

                charbuff_clear(cb);
            }
            printf("> ");
        } else {
            charbuff_push(cb, car);
        }
    }

    charbuff_free(cb);
    return 0;
}
