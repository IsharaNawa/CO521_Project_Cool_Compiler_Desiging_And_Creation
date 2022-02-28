/*
*  cool.y
*              Parser definition for the COOL language.
*
*/
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"
  
  extern char *curr_filename;
  
  
  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
  for the location of tokens */
    
    extern int node_lineno;          /* set before constructing a tree node
    to whatever you want the line number
    for the tree node to be */
      
      
      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;
    
    
    #define SET_NODELOC(Current)  \
    node_lineno = Current;
    
    /* IMPORTANT NOTE ON LINE NUMBERS
    *********************************
    * The above definitions and macros cause every terminal in your grammar to 
    * have the line number supplied by the lexer. The only task you have to
    * implement for line numbers to work correctly, is to use SET_NODELOC()
    * before constructing any constructs from non-terminals in your grammar.
    * Example: Consider you are matching on the following very restrictive 
    * (fictional) construct that matches a plus between two integer constants. 
    * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):
    
    plus_consts	: INT_CONST '+' INT_CONST 
    
    * where INT_CONST is a terminal for an integer constant. Now, a correct
    * action for this rule that attaches the correct line number to plus_const
    * would look like the following:
    
    plus_consts	: INT_CONST '+' INT_CONST 
    {
      // Set the line number of the current non-terminal:
      // ***********************************************
      // You can access the line numbers of the i'th item with @i, just
      // like you acess the value of the i'th exporession with $i.
      //
      // Here, we choose the line number of the last INT_CONST (@3) as the
      // line number of the resulting expression (@$). You are free to pick
      // any reasonable line as the line number of non-terminals. If you 
      // omit the statement @$=..., bison has default rules for deciding which 
      // line number to use. Check the manual for details if you are interested.
      @$ = @3;
      
      
      // Observe that we call SET_NODELOC(@3); this will set the global variable
      // node_lineno to @3. Since the constructor call "plus" uses the value of 
      // this global, the plus node will now have the correct line number.
      SET_NODELOC(@3);
      
      // construct the result node:
      $$ = plus(int_const($1), int_const($3));
    }
    
    */
    
    
    
    void yyerror(char *s);        /*  defined below; called for each parse error */
    extern int yylex();           /*  the entry point to the lexer  */
    
    /************************************************************************/
    /*                DONT CHANGE ANYTHING IN THIS SECTION                  */
    
    Program ast_root;	      /* the result of the parse  */
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}
    
    /* A union of all the types that can be the result of parsing actions. */
    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      char *error_msg;
    }
    
    /* 
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.
    
    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276 
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279 
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283
    
    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/
    
    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison 
    documentation for details). */
    
    /* Declare types for the grammar's non-terminals. */
    %type <program> program
    %type <classes> class_list			
    %type <class_> class

    /*newly added types*/

    %type <features> feature_list		
    %type <features> features           
    %type <feature> feature
    
    
    %%
    /* 
    Save the root of the abstract syntax tree in a global variable.
    */

    /*root node of the parser always should be the program it self, therefore
      what is required in the program is defined here
    */
    program	:

	    /*
	    	program consists of one or more classes , therefore that is defined here.
	    	root node of the AST is defined as the program it self.
	    */

	    class_list{		/*program is a list of classes*/ 
	    	@$ = @1; 
	    	ast_root = program($1); 
	    };
    
    class_list :

    	/*
    		definition of the class_list is defined here
    	*/

	    class { /* class_list can be made up of only one calss(main class). 
	    		here class needs to be defined below.
	    		*/

	    	/* make a single class instance using the constructor */
	      	$$ = single_Classes($1);

	      	/* add the class to the parser */
	      	parse_results = $$;	 
	    } | 

	    class_list class { 	/* class_list can be multilple classes */

	    	/* create a new class using constructor and append that to the class list */
	      	$$ = append_Classes($1,single_Classes($2));

	      	/* add the class_list to the parser */ 
	      	parse_results = $$; 
	    };
    
    /* If no parent is specified, the class inherits from the Object class. */


    class	:
    	/* 
    		definititon of the single class
    	 */

    	/*class is defined giving only the name of the class as the type id.
    	  Here, the class inherits from the Object class. 	
    	*/ 
	    CLASS TYPEID '{' feature_list '}' ';'{ 

	    	/* create a class using the constructor.
	    	   here name of the parent class is set as the Object.
	    	   What is inside each class, there is a list of 
	    	   features.
	    	 */
	        $$ = class_($2,idtable.add_string("Object"),$4,
	        stringtable.add_string(curr_filename)); 
	    } |

	    /* class can also be inherited from its parent class,
	      in this approach we neeed to defined the name of the 
	      parent class
	    */
	     CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'{

	     	/* create a class using the constructor.
	    	   here name of the parent class is set as the 4th token($4).
	    	   What is inside each class, there is a list of 
	    	   features.
	    	 */
	        $$ = class_($2,$4,$6,stringtable.add_string(curr_filename));

	    };
    
    /* Feature list may be empty, but no empty features in list. */

    feature_list :
    	/* 
    		Definition of each feature_list.
    	   	Feature list is the set of statements in each class
    	 */

	    { 
	    	/* inside the class can be empty.
	    	   Hence, feature list can be empty.
	     	*/ 
	      	$$ = nil_Features(); 
	    }|  
	    features { /*feature list can consists with features*/

	    	/*
	    		Here we need to defined what does feature mean, below.
	    	*/

	    	/*just get features and consider that as the feature list*/
	        $$ = $1;
	    };

    features :
    	/*
    		Definition of each features
    	*/

	    feature ';' { 	
	    	/* Features can be consists of only one feature.
	    		Here we need to create a new feature using the 
	    		constructor and get that as features. We need to
	    		define the feature below.
	    	*/
	      	$$ = single_Features($1); 
	    }| 
	    features feature ';' {
	    	/* features can be considered as features and one other 
	    	   single feature. Here , we need to create a new feature
	    	   for the single feature using the constructor and append
	    	   that to the features list.
	    	*/ 
	      	$$ = append_Features($1, single_Features($2)); 
	    };

    feature :

    	/*
    		Definition of each feature
    	*/

    	/* as per the cool manual , feature can be considered as a 
    		method or the function call. Here name of the function is
    		followed by the formal_list inside brackets then the 
    		return type of the method should be specified. In the
    		function definition, there is a set of experssions.
    	 */
      	OBJECTID '(' formal_list ')' ':' TYPEID '{' expression '}' {

      		/*create a method instance using the constructor and pass the
      		arguments as specified in the line 182 of cool-tree.h file.
      		Also we need to define the formal_list below.
      		*/
        	$$ = method($1,$3,$6, $8);
      	} |

      	OBJECTID ':' TYPEID {

      		/*feature can also be a variable with its' type.
      		This is an attirbute. Here use the constructor of attribute and
      		pass arguments as specified in the line 207 in cool-tree.h
      		*/
        	$$ = attr($1, $3 , no_expr());
      	} | 

	    OBJECTID : TYPEID ASSIGN expression {

	    	/*feature also can be a assigning expression, here also use the
	    	attr constructor to create an attribute*/
	    	$$ = attr($1, $3 , $5);
	    };

    
    
    
    /* end of grammar */
    %%
    
    /* This function is called automatically when Bison detects a parse error. */
    void yyerror(char *s)
    {
      extern int curr_lineno;
      
      cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
      << s << " at or near ";
      print_cool_token(yychar);
      cerr << endl;
      omerrs++;
      
      if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
    }
    
    