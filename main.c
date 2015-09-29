#define TESTS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef TESTS
#include <assert.h>
#endif

/*
Shim pour avoir des booleans.
*/
typedef enum bool { false = 0, true = 1 } bool;

/*
Type algébrique représentant une opération qui peut produire une erreur.
Emprunté de https://doc.rust-lang.org/nightly/std/result/enum.Result.html
*/
typedef struct result {
    bool is_ok;
    union {
        void* ok;
        struct {
            int code;
            char* err;
        };
    };
} result;

/*
Emprunté de https://doc.rust-lang.org/nightly/std/macro.try!.html
*/
#define try(expr, var) if (!expr.is_ok) return err(expr.code, expr.err); else var = expr.ok;

/*
Représente un nombre d'une taille illimité.
*/
typedef struct nombre {
    bool positif;
    int len;
    char* chiffres;
} nombre;

/* misc */
inline int max(int, int);
inline bool is_chiffre(char);
inline char chiffre_to_car(char);
inline char car_to_chiffre(char);
/* result */
result ok(void*);
result err(int, char*);
/* nombre */
nombre* nombre_new(char*);
nombre* nombre_clone(nombre*);
int nombre_compare(nombre*, nombre*);
nombre* nombre_add(nombre*, nombre*);
nombre* nombre_sub(nombre*, nombre*);
char* nombre_format(nombre*);
/* tests unitaires */
#ifdef TESTS
void test_nombre_new();
void test_nombre_clone();
void test_nombre_compare();
void test_nombre_add();
void test_nombre_sub();
void test();
#endif

inline int max(int a, int b) {
    return a > b ? a : b;
}

inline bool is_chiffre(char c) {
    return c >= '0' && c <= '9';
}

inline char chiffre_to_car(char chiffre) {
    return chiffre + '0';
}

inline char car_to_chiffre(char car) {
    return car - '0';
}

result ok(void* ok) {
    result res;
    res.is_ok = true;
    res.ok = ok;
    return res;
}

result err(int code, char* err) {
    result res;
    res.is_ok = false;
    res.code = code;
    res.err = err;
    return res;
}

nombre* nombre_new(char* text) {
    int i, j;
    size_t len;
    nombre* nb;

    len = strlen(text);
    nb = malloc(sizeof(nombre));
    nb->positif = true;
    nb->len = len;

    if (len > 0 && text[0] == '-') {
        nb->positif = false;
        nb->len = --len;
        text++;
    }

    nb->chiffres = malloc(sizeof(char) * len);

    for (i = 0, j = len - 1; i < len; i++, j--) {
        nb->chiffres[i] = car_to_chiffre(text[j]);
    }

    return nb;
}

nombre* nombre_clone(nombre* nb) {
    nombre* new;

    new = malloc(sizeof(nombre));
    new->positif = nb->positif;
    new->len = nb->len;
    new->chiffres = malloc(nb->len);
    memcpy(new->chiffres, nb->chiffres, nb->len);

    return new;
}

/**
 * 0 est égal à -0
 *  1 : a est plus grand que b
 * -1 : a est plus petit que b
 *  0 : a et b sont égaux
 */
int nombre_compare(nombre* a, nombre* b) {
    bool positif;
    int i;

    /* 0 est -0 */
    if (a->len == 1 && b->len == 1 && a->chiffres[0] == 0 && b->chiffres[0] == 0)
        return 0;

    if (a->positif && !b->positif)
        return 1;
    if (!a->positif && b->positif)
        return -1;

    positif = a->positif && b->positif;
    /* a à plus de chiffres que b */
    if (a->len > b->len) return positif ? 1 : -1;
    /* a à moins de chiffres que b */
    if (a->len < b->len) return positif ? -1 : 1;
    /* les deux nombres ont la même taille */
    for (i = a->len - 1; i >= 0; i--) {
        if (a->chiffres[i] > b->chiffres[i]) return positif ? 1 : -1;
        if (a->chiffres[i] < b->chiffres[i]) return positif ? -1 : 1;
    }
    /* le signe et tous les chiffres sont identiques */
    return 0;
}

/*
    Table de branchement:

      a + b => add(a, b)
     -a + b => sub(b, a)
     a + -b => sub(a, b)
    -a + -b => -add(a, b)
*/
nombre* nombre_add(nombre* a, nombre* b) {
    printf("ADD: %s & %s\n", nombre_format(a), nombre_format(b));
    int i, max_len;
    char res, carry;
    nombre *nb, *r;

    /* a + -b */
    if (a->positif && !b->positif) {
        b->positif = true;
        r = nombre_sub(a, b);
        b->positif = false;
        return r;
    /* -a + b */
    } else if (!a->positif && b->positif) {
        a->positif = true;
        r = nombre_sub(b, a);
        a->positif = false;
        return r;
    }

    max_len = max(a->len, b->len) + 1;
    carry = 0;

    nb = malloc(sizeof(nombre));
    /* a + b  ou  -a + -b */ 
    nb->positif = a->positif && b->positif;
    nb->chiffres = malloc(max_len);

    // assume deux nombres négatifs
    for (i = 0; i < max_len; i++) {
        if (i < a->len && i < a->len) {
            res = a->chiffres[i] + b->chiffres[i];
        } else if (i < a->len) {
            res = a->chiffres[i];
        } else if (i < b->len) {
            res = b->chiffres[i];
        } else {
            nb->chiffres[i] = carry;
            break;
        }

        res += carry;
        if (res >= 10) {
            res -= 10;
            carry = 1;
        } else carry = 0;

        nb->chiffres[i] = res;
    }

    nb->len = carry == 1 ? max_len : max_len - 1;

    return nb;
}

/*
    Table de branchement:

     a - -b => add(a, b)
    -a - -b => sub(b, a)
      a - b => sub(a, b)
     -a - b => -add(a, b)
*/
nombre* nombre_sub(nombre *a, nombre *b) {
    printf("SUB: %s & %s\n", nombre_format(a), nombre_format(b));
    int i, max_len;
    char res, carry, diminuende, diminuteur;
    nombre *nb, *tmp, *r;

    /* -a - b */
    if (!a->positif && b->positif) {
        a->positif = true;
        r = nombre_add(a, b);
        r->positif = a->positif = false;
        return r;
    /* a - -b  */
    } else if (a->positif && !b->positif) {
        b->positif = true;
        r = nombre_add(a, b);
        b->positif = false;
        return r;
    /* -a - -b */
    } else if (!a->positif && !b->positif) {
        a->positif = b->positif = true;
        r = nombre_sub(b, a);
        r->positif = false;
        a->positif = b->positif = true;
        return r;
    }
    /* a - b */

    max_len = max(a->len, b->len);
    carry = 0;

    nb = malloc(sizeof(nombre));
    nb->positif = true;
    nb->len = max_len;
    nb->chiffres = malloc(max_len);

    switch (nombre_compare(a, b)) {
        case 0:
            return nombre_new("0");
        case -1:
            tmp = a;
            a = b;
            b = tmp;
            nb->positif = false;
            break;
    }

    for (i = 0; i < max_len; i++) {
        if (i < a->len && i < b->len) {
            diminuende = a->chiffres[i];
            diminuteur = b->chiffres[i];
        } else if (i < a->len) {
            diminuende = a->chiffres[i];
            diminuteur = 0;
        } else if (i < b->len) {
            diminuende = 0;
            diminuteur = b->chiffres[i];
        }

        diminuende -= carry;
        if (diminuende < diminuteur) {
            res = 10 + diminuende - diminuteur;
            carry = 1;
        } else {
            res = diminuende - diminuteur;
            carry = 0;
        }
        nb->chiffres[i] = res;
    }

    // TODO: better algorithm
    /* enlever les zéros en extra */
    for (int i = max_len - 1; i > 0; i--) {
        if (nb->chiffres[i] == 0) {
            nb->len--;
        }
    }

    return nb;
}

char* nombre_format(nombre* self) {
    int i, j;
    char* text;
    char* start;

    text = malloc(self->len + 2);
    start = self->positif ? text : (text + 1);

    for (i = 0, j = self->len - 1; i < self->len; i++, j--) {
        start[i] = chiffre_to_car(self->chiffres[j]);
    }

    if (self->positif) {
        text[self->len] = '\0';
    } else {
        text[0] = '-';
        text[self->len + 1] = '\0';
    }

    return text;
}

#ifdef TESTS

void test_nombre_new() {
    assert(nombre_new("5")->positif == true);
    assert(nombre_new("-5")->positif == false);
    assert(strcmp(nombre_new("-1234")->chiffres, "\x04\x03\x02\x01") == 0);
}

void test_nombre_clone() {
    nombre* a = nombre_new("-52");
    nombre* b = nombre_clone(a);
    assert(a->positif == b->positif);
    assert(a->len == b->len);
    assert(strcmp(a->chiffres, b->chiffres) == 0);
}

void test_nombre_compare() {
    assert(nombre_compare(nombre_new("13"), nombre_new("14")) == -1);
    assert(nombre_compare(nombre_new("-13"), nombre_new("-14")) == 1);
    assert(nombre_compare(nombre_new("-13"), nombre_new("14")) == -1);
    assert(nombre_compare(nombre_new("13"), nombre_new("-14")) == 1);
    assert(nombre_compare(nombre_new("13"), nombre_new("13")) == 0);
}

void test_nombre_add() {
    nombre *a, *b;

    a = nombre_new("14");
    b = nombre_new("14");
    assert(nombre_compare(nombre_add(a, b), nombre_new("28")) == 0);

    a = nombre_new("-25");
    b = nombre_new("25");
    assert(nombre_compare(nombre_add(a, b), nombre_new("0")) == 0);

    a = nombre_new("-25");
    b = nombre_new("26");
    assert(nombre_compare(nombre_add(a, b), nombre_new("1")) == 0);

    a = nombre_new("-26");
    b = nombre_new("25");
    assert(nombre_compare(nombre_add(a, b), nombre_new("-1")) == 0);

    a = nombre_new("25");
    b = nombre_new("-25");
    assert(nombre_compare(nombre_add(a, b), nombre_new("0")) == 0);

    a = nombre_new("-14");
    b = nombre_new("-14");
    assert(nombre_compare(nombre_add(a, b), nombre_new("-28")) == 0);
}

void test_nombre_sub() {
    nombre *a, *b;

    a = nombre_new("14");
    b = nombre_new("7");
    assert(nombre_compare(nombre_sub(a, b), nombre_new("7")) == 0);

    a = nombre_new("-25");
    b = nombre_new("-25");
    assert(nombre_compare(nombre_sub(a, b), nombre_new("0")) == 0);

    a = nombre_new("-25");
    b = nombre_new("25");
    assert(nombre_compare(nombre_sub(a, b), nombre_new("-50")) == 0);

    a = nombre_new("25");
    b = nombre_new("-25");
    assert(nombre_compare(nombre_sub(a, b), nombre_new("50")) == 0);

    a = nombre_new("-14");
    b = nombre_new("-7");
    assert(nombre_compare(nombre_sub(a, b), nombre_new("-7")) == 0);
}

/* Le tests ne free pas la mémoire puisque le programme s'arrête après. */
void test() {
    puts("Exécution des tests car `#define TESTS = 1`");
    test_nombre_new();
    test_nombre_clone();
    test_nombre_compare();
    test_nombre_add();
    test_nombre_sub();
    puts("Pas d'erreur!");
}
#endif

int main(int argc, char* argv[]) {
    /* support pour les tests unitaires */
    #ifdef TESTS
    if (argc >= 2) {
        if (strcmp(argv[1], "--test") == 0) {
            test();
            exit(0);
        }
    }
    #endif

    /* début du programme */
    char variables[26];
    memset(variables, 0, 26);

    //
    // bool quit = false;
    // while (!quit) {
    //     printf("> ");
    //     for (;;) {
    //         int c = getchar();
    //         if (c == EOF) {
    //             quit = true;
    //             break;    test_nombre_clone();
    //         }
    //         if (c == '\n') break;
    //         putchar(c);
    //     }
    //     putchar('\n');
    // }
    return 0;
}
