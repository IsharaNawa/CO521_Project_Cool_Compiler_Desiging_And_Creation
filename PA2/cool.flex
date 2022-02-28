/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>


/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex


/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

 /* declarations of the custom functions */
bool string_too_long();
int string_length_err();

%}

/*
 * Define names for regular expressions here.
 */

 /* boolean vaiables to handle strings amds comments */
%x STRING
%x COMMENT

/*keywords*/
CLASS 	(?i:class)
ELSE 	(?i:else)
FI 	(?i:fi)
IF 	(?i:if)
IN 	(?i:in)
INHERITS (?i:inherits)
LET 	(?i:let)
LOOP 	(?i:loop)
POOL 	(?i:pool)
THEN 	(?i:then)
WHILE 	(?i:while)
CASE 	(?i:case)
ESAC 	(?i:esac)
NEW 	(?i:new)
OF 	(?i:of)
ISVOID 	(?i:isvoid)
NOT 	(?i:not)

/*integers*/
DIGIT [0-9]
INT_CONST {DIGIT}+

/*identifiers*/
LETTER [a-zA-Z_]
 /*type id are started with a uppercase letter and object id are started
  with a lowercase letters*/
TYPEID [A-Z]({DIGIT}|{LETTER})*
OBJECTID [a-z]({DIGIT}|{LETTER})*

/*whitespace*/
NEWLINE \n
WHITESPACE  [ \t]*

/*operators*/
DARROW "=>"
ASSIGN "<-"
LESS "<"
LE "=<"
AT "@"
NEGATION "~"
EQUAL "="
FULLSTOP "."
DASH "-"
COMMA ","
PLUS "+"
MULTIPLY "*"
DIVIDE "/"
OPENCURLYBRACES "{"
CLOSECURLYBRACES "}"
OPENPARANTHESIS "("
CLOSEPARANTHESIS ")"
COLON ":"
SEMICOLON ";"

/*boolean values*/
TRUE true
FALSE false

/*comments*/
SINGLELINECMT --.*\n

/*
STR_CONST
*/

%%

 /*keywords*/
{CLASS} {
	return (CLASS);
}

{ELSE} {
	return (ELSE);
}

{FI} {
	return (FI);
}

{IF} {
	return (IF);
}

{IN} {
	return (IN);
}

{INHERITS} {
	return (INHERITS);
} 

{LET} {
	return (LET);
}

{LOOP} {
	return (LOOP);
}

{POOL} {
	return (POOL);
}

{THEN} {
	return (THEN);
}

{WHILE} {
	return (WHILE);
}

{CASE} {
	return (CASE);
}

{ESAC} {
	return (ESAC);
}

{NEW} {
	return (NEW);
}

{OF} {
	return (OF);
}

{ISVOID} {
	return (ISVOID);
}

{NOT} {
	return (NOT);
}

 /*integers*/
{INT_CONST} { 
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST; 
}
 
 /*boolean values*/
{TRUE} {
    cool_yylval.boolean = true;
    return BOOL_CONST;
}

{FALSE} {
    cool_yylval.boolean = false;
    return BOOL_CONST;
}

 /*identifiers*/
 /*identifiers must be added to the idtable*/
{OBJECTID} { 
    cool_yylval.symbol = idtable.add_string(yytext); 
    return OBJECTID; 
}

{TYPEID} { 
    cool_yylval.symbol = idtable.add_string(yytext); 
    return TYPEID; 
}

 /* strings */
\" {
	/*when double quatation is found, start of the string
	 is found.
	 also a pointer to store the string is also initialized.
	 */
    BEGIN(STRING);
    string_buf_ptr = string_buf;
}

 /* to end string */
<STRING>\" {
	/*when double quatation is found and STRING variable is high,
	 that means the string is successfully closed. Therefore
	 initial state of the system is obtained.
	 */
    BEGIN(INITIAL);

    /*if the characters in the string is too much, print the error*/
    if (string_too_long()) return string_length_err();

    /*reset the char array*/
    string_buf_ptr = 0;

    /*add the string to the table*/
    cool_yylval.symbol = stringtable.add_string(string_buf);

    /*return the token*/
    return STR_CONST;
}

 /* to send an error message if the string is not closed */
<STRING><<EOF>> {
	/*if the analyzer found EOF value, before string is closed, 
	that means, the string is not closed appropriately. Therefore
	return the error
	*/
    cool_yylval.error_msg = "EOF in string constant";
    return ERROR;
}

 /* to read a newline in the string */
<STRING>\\[n] {
	/*if the analyzer found newline character, before string is closed, 
	that means, the string is not closed appropriately. Therefore
	print the string too long error.
	*/
    if (string_too_long()) return string_too_long();
    *string_buf_ptr++ = '\n';
}

 /* if the string contains invalid charactor, returns an error*/
<STRING>\0 {
	/*if the analyzer found null character, before string is closed, 
	that means, the string is not closed appropriately. Therefore
	print the null character error.
	*/
    cool_yylval.error_msg = "String contains null character";
    return ERROR;
}

 /* to read each letter in the string */
<STRING>. {
	/*
	if any of the above errors do not happens, add the character to 
	the char array and move to the next character.
	*/
    if (string_too_long()) return string_length_err();
    *string_buf_ptr++ = *yytext;
}

 /*whitespace*/
 /*new line should be ignored, however the number of lines must
  be incremented*/
{NEWLINE} {
	curr_lineno++;
}

 /*every white space should be ignored*/
{WHITESPACE} {}
 
 /*operators and special notations:
  for operators and special notations
  just return the text*/
{DARROW} { 
	return DARROW; 
}

{ASSIGN} { 
	return ASSIGN;
}

{LESS} { 
	return *yytext; 
}

{AT} { 
	return *yytext; 
}

{NEGATION} { 
	return *yytext; 
}

{EQUAL} { 
	return *yytext;
}

{FULLSTOP} { 
	return *yytext; 
}

{DASH} { 
	return *yytext; 
}

{COMMA} { 
	return *yytext; 
}

{PLUS} { 
	return *yytext; 
}

{MULTIPLY} { 
	return *yytext; 
}

{DIVIDE} { 
	return *yytext; 
}

{OPENPARANTHESIS} { 
	return *yytext; 
}

{CLOSEPARANTHESIS} { 
	return *yytext; 
}

{OPENCURLYBRACES} { 
	return *yytext; 
}

{CLOSECURLYBRACES} { 
	return *yytext; 
}

{SEMICOLON} { 
	return *yytext; 
}

{COLON} { 
	return *yytext; 
}

 /*when comment is started, make the comment variable state to high*/
"(*" {
    BEGIN(COMMENT);
}
 
 /*check if EOF is followed by the opening braces, that means comment is not closed,
 therefore print the error message*/
<COMMENT><<EOF>> {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return ERROR;
}

 /*check if the a new line is after the comment opening, if the number of lines should be incremented*/
<COMMENT>\n { curr_lineno++; }

 /*disregard the characters after opening a comment*/
<COMMENT>. { }

 /*if a comment is closed, the state is resetted to initial state*/
<COMMENT>"*)" {
    BEGIN(INITIAL);
}

 /*error handling on multiline comments*/
"*)" {
    cool_yylval.error_msg = "Unmatched *)";
    return ERROR;
}

 /*only the number of lines must be incremented*/
{SINGLELINECMT} { curr_lineno++; }



 /*every other tokens are error tokens*/
. {
    cool_yylval.error_msg = strdup(yytext);
    return ERROR;
}


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%

 /* returns true if string is too long */
bool string_too_long() { 
    return (string_buf_ptr - string_buf) + 1 > MAX_STR_CONST; 
}

 /* returns the error index if the string is too long */
int string_length_err() { 
    BEGIN(INITIAL);
    cool_yylval.error_msg = "String constant too long";
    return ERROR;
}