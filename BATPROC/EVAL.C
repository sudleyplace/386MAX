// EVAL.C - Expression analyzer for BATPROC batch language
//  Copyright (c) 1990 Rex C. Conn  GNU General Public License version 3
//  This routine supports the standard arithmetic functions: +, -, *, /,
//    %, and the unary operators + and -

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <setjmp.h>

#include "batproc.h"


static void level1(long *);
static void level2(long *);
static void level3(long *);
static void level4(long *);


#define ADD 0
#define SUBTRACT 1
#define MULTIPLY 2
#define DIVIDE 3
#define MODULO 4
#define OPEN_PAREN 5
#define CLOSE_PAREN 6

#define MAX_DIGITS 20

static char *line;
static char token[MAX_DIGITS+1];

static char tok_type;
static char delim_type;

static jmp_buf env;


#define DELIMITER	1
#define NUMBER		2


// check for a operator character + - * / % ( )
static char is_operator(void)
{
	static char operators[] = "+-*/%()";
	register int i;

	for (i = 0; (operators[i] != '\0'); i++) {

		if (*line == operators[i]) {
			delim_type = (char)i;
			return (*line);
		}
	}

	return 0;
}


static void get_token(void)
{
	register int i = 0;

	tok_type = 0;
	line = skipspace(line);

	// get the next token (number or operator)
	if (isdigit(*line)) {

		for (tok_type = NUMBER; (i < MAX_DIGITS); line++) {
			if (isdigit(*line))
				token[i++] = *line;
			else if (*line != ',')
				break;
		}

	} else if ((token[i++] = is_operator()) != '\0') {
		tok_type = DELIMITER;
		line++;
	}

	token[i] = '\0';
}


static void arith(register int op, long *r, long *h)
{
	if (op == ADD)
		*r = *r + *h;
	else if (op == SUBTRACT)
		*r = *r - *h;
	else if (op == MULTIPLY)
		*r = (*r) * (*h);
	else if ((op == DIVIDE) || (op == MODULO)) {

		if (*h == 0L)		// divide by 0 not allowed
			longjmp(env,ERROR_BATPROC_DIVIDE_BY_ZERO);

		if (op == DIVIDE)
	   		*r = (*r) / (*h);
		else 
			*r = (*r) % (*h);
	}
}


// do addition & subtraction
static void level1(long *result)
{
	register int op;
	long hold = 0L;

	level2(result);

	while ((tok_type == DELIMITER) && ((delim_type == ADD) || (delim_type == SUBTRACT))) {
		op = delim_type;
		get_token();
		level2(&hold);
		arith(op,result,&hold);
	}
}


// do multiplication & division & modulo
static void level2(long *result)
{
	register int op;
	long hold = 0L;

	level3(result);

	while ((tok_type == DELIMITER) && ((delim_type == MULTIPLY) || (delim_type == DIVIDE) || (delim_type == MODULO))) {
		op = delim_type;
		get_token();
		level3(&hold);
		arith(op,result,&hold);
	}
}


// process unary + & -
static void level3(long *result)
{
	register int is_unary = -1;

	if ((tok_type == DELIMITER) && ((delim_type == ADD) || (delim_type == SUBTRACT))) {
		is_unary = delim_type;
		get_token();
	}

	level4(result);

	if (is_unary == ADD)
		*result = +(*result);
	else if (is_unary == SUBTRACT)
		*result = -(*result);
}


// process parentheses
static void level4(long *result)
{
	// is it a parenthesis?
	if ((tok_type == DELIMITER) && (delim_type == OPEN_PAREN)) {

		get_token();
		level1(result);
		if (delim_type != CLOSE_PAREN)
			longjmp(env,ERROR_BATPROC_UNBALANCED_PARENS);
		get_token();

	} else if (tok_type == NUMBER) {
		*result = atol(token);
		get_token();
	}

	if ((tok_type != DELIMITER) && (tok_type != NUMBER) && (*line))
		longjmp(env,ERROR_BATPROC_BAD_SYNTAX);
}


// evaluate the algebraic expression
int pascal evaluate(register char *expr)
{
	register int n;
	long answer = 0L;

	if ((n = setjmp(env)) != 0)
		return (error(n,expr));

	if (((line = expr) != NULL) && (*line)) {
		get_token();
		if (*token == '\0')
			longjmp(env,ERROR_BATPROC_NO_EXPRESSION);
		level1(&answer);
	}

	sprintf(expr,"%ld",answer);

	return 0;
}

