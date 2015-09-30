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

/* convertit une valeur numérique [0-9] en son caractère */
char val_to_car(char);
/* convertit un caractère ['0'-'9'] en sa valeur numérique */
char car_to_val(char);

/* créer un nombre à partir d'une string */
struct num* num_from_str(const char*);
/* créer un clone complet du nombre */
struct num* num_clone(const struct num*);
/* libérer la mémoire utilisée par un nombre */
void num_free(struct num*);
/* formatter le nombre en string */
char* num_to_str(const struct num*);

/* créer un  nouveau charbuff avec la capacitée donnée */
struct charbuff* charbuff_new(int cap);
/* ajouter un caractère et redimensionner au besoin */
bool charbuff_push(struct charbuff*, char);
/* disposer du texte contenu, mais sauvegarder l'espace mémoire  */
void charbuff_clear(struct charbuff*);
/* libérer la mémoire utilisé */
void charbuff_free(struct charbuff*);

/* implémentation */

inline char val_to_car(char val) {
    return val + '0';
}

inline char car_to_val(char car) {
    return car - '0';
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
            charbuff_free(cb);
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

int main(int argc, char **argv) {
    struct num *n = num_from_str("123456");
    struct num *c = num_clone(n);
    printf("%d %d %s\n", n->pos, n->len, num_to_str(n));
    printf("%d %d %s\n", c->pos, c->len, num_to_str(c));
    return 0;
}
