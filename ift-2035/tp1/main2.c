#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum { false, true } bool;

struct digit {
    char val;
    struct digit *next;
};

struct num {
    bool pos;
    int len;
    struct digit *first;
};

struct num* num_new(const char*);
void num_destroy(struct num*);
char* num_to_string(struct num*);

struct num* num_new(const char *text) {
    int len, i, lo;
    struct num *n;
    struct digit *p, *d;

    len = strlen(text);
    p = NULL;

    n = malloc(sizeof(struct num));
    if (n == NULL) return NULL;

    n->pos = text[0] != '-';
    n->len = 0;
    lo = !n->pos;

    for (i = len - 1; i >= lo; i--) {
        d = malloc(sizeof(struct digit));
        d->val = text[i];
        n->len++;
        if (p == NULL)
            n->first = p = d;
        else
            p->next = d;
        p = d;
    }

    return n;
}

void num_destroy(struct num *n) {
    struct digit *d, *t;

    d = n->first;
    while (d != NULL) {
        t = d->next;
        free(d);
        d = t;
    }

    free(n);
}

char* num_to_string(struct num *n) {
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
        text[i--] = d->val;
        d = d->next;
    }
    text[len - 1] = '\0';

    if (!n->pos) {
        text[0] = '-';
    }

    return text;
}

int main() {
    struct num *n = num_new("123456");
    printf("%s\n", num_to_string(n));
    num_destroy(n);
    return 0;
}
