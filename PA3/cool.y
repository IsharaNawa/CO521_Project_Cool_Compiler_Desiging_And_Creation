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

    /*related to features*/
    %type <features> feature_list		
    %type <features> features           
    %type <feature> feature

    /*related to formals*/
    %type <formals> formal_list
    %type <formal> formal

    /*related to expressions*/
    %type <expression> expression
    %type <expressions> expr_parameters
    %type <expressions> expr_statements
    %type <expression> expr_let
    %type <cases> expr_case
    %type <case_> single_case
    
    /* writing the procedence rules*/

    /*
      Order of precedence is shown in the page 16 in 
      cool-manual.pdf from highest priority to the lowest.
      But in here, we declare the precedence from lowest to
      the highest.

      According to the section 2.2 in the Bison manual, the 
      precedence can be declared as,
      %[left/right/nonassoc] [token]

    */

    %right ASSIGN
    %left NOT
    %nonassoc LE '<' '='
    %left '+' '-'
    %left '*' '/'
    %left ISVOID
    %left '~'
    %left '@'
    %left '.'

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

	    class_list {

        /*program is a list of classes*/

	    	@$ = @1; 
	    	ast_root = program($1);

	    };
    
    class_list :

    	/*
    		definition of the class_list is defined here
    	*/

	    class {

        /* 
          class_list can be made up of only one calss(main class). 
	    		here class needs to be defined below.
	    	*/

	    	/* make a single class instance using the constructor */
	        $$ = single_Classes($1);

	      /* add the class to the parser */
	      	parse_results = $$;

	    } | 

	    class_list class {

	    	/* create a new class using constructor and append that to the 
        class list */
	      	$$ = append_Classes($1,single_Classes($2));

	      /* add the class_list to the parser */ 
	      	parse_results = $$;

	    };
    
    class	:

    	/* 
    		definititon of the single class
    	*/

    	/*
        class is defined giving only the name of the class as the type id.
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

	    /* 
        class can also be inherited from its parent class,
	      in this approach we neeed to defined the name of the 
	      parent class
	    */

	    CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'{

	     	/* 
          create a class using the constructor.
	    	  here name of the parent class is set as the 4th token($4).
	    	  What is inside each class, there is a list of 
	    	  features.
	    	*/

	      $$ = class_($2,$4,$6,stringtable.add_string(curr_filename));

	    } |

      /*
        error case 1 : when there is an error in the feature list
        it is identified.
      */

      CLASS TYPEID '{' error '}' ';' {

        /*
          Discard the current lookahead token. This is useful primarily in 
          error rules and apply a null node to the parse tree
        */ 
          yyclearin; 
          $$ = NULL; 
      } |

      /*
        error case 2 : when there is an error in the class signature,
        it is identified.
      */

      CLASS error '{' feature_list '}' ';' {
        /*
          Discard the current lookahead token. This is useful primarily in
          error rules and apply a null node to the parse tree
        */

          yyclearin;
          $$ = NULL; 
      } |

      /*
        error case 3 : when there is an error in the feature list or
        function definition,it is identified.
      */

      CLASS error '{' error '}' ';' {
        /*
          Discard the current lookahead token. This is useful primarily in error rules and apply a null node to the parse tree
        */  
          yyclearin;
          $$ = NULL; 
      };
    

    feature_list :

    	/* 
    		Definition of each feature_list.
    	  Feature list is the set of statements in each class
    	*/

	    { 
	    	/*
          inside the class can be empty.
	    	  Hence, feature list can be empty.
	     	*/ 
	      	$$ = nil_Features(); 
	    }|

	    features {

        /*feature list can consists with features*/

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

	    	/* 
          Features can be consists of only one feature.
	    		Here we need to create a new feature using the 
	    		constructor and get that as features. We need to
	    		define the feature below.
	    	*/

	      	$$ = single_Features($1);

	    }|

	    features feature ';' {

	    	/* 
          features can be considered as features and one other 
	    	  single feature. Here , we need to create a new feature
	    	  for the single feature using the constructor and append
	    	  that to the features list.
	    	*/

	      	$$ = append_Features($1, single_Features($2));

	    } |

      error ';' {

        /* 
          when there is an error in the features, 
          it is identified
        */ 

        /*
          Discard the current lookahead token. This is useful primarily in error rules and apply a null node to the parse tree
        */

          yyclearin; 
          $$ = NULL;

      };

    feature :

    	/*
    		Definition of each feature
    	*/

    	/*
        as per the cool manual , feature can be considered as a 
    		method or the function call. Here name of the function is
    		followed by the formal_list inside brackets then the 
    		return type of the method should be specified. In the
    		function definition, there is a set of experssions.
    	*/

      OBJECTID '(' formal_list ')' ':' TYPEID '{' expression '}' {

      	/*
          create a method instance using the constructor and pass the
      		arguments as specified in the line 182 of cool-tree.h file.
      		Also we need to define the formal_list below.
      	*/

        	$$ = method($1,$3,$6, $8);

      } |

      OBJECTID ':' TYPEID {

      	/*
          feature can also be a variable with its' type.
      		This is an attirbute. Here use the constructor of attribute and
      		pass arguments as specified in the line 207 in cool-tree.h
      	*/

        	$$ = attr($1, $3 , no_expr());

      } | 

	    OBJECTID ':' TYPEID ASSIGN expression {

	    	/*
          feature also can be a assigning expression, here also use the
	    	  attr constructor to create an attribute
        */

	    	$$ = attr($1, $3 , $5);

	    };

	formal_list : 

		/*
			Definition of the list of formals
		*/

		formal {

      /* 
        formal_list can be made up of only one formal. 
	    	Here formal needs to be defined below.
	    */

	    /* make a single formal instance using the constructor */
	      $$ = single_Formals($1);

	    } | 

	    formal_list ',' formal {

        /* 
          formal_list can be multilple formals
        */

	    	/* 
          create a new formal using constructor and append that to the 
          formal list 
        */
	      	$$ = append_Formals($1,single_Formals($3));

	    } |

	    {
	    	/*
          Formal also can be made up of empty formal
        */
	    	$$ = nil_Formals();

	    };

	formal : 

		/*
			Definition of a single formal
		*/

		OBJECTID ':' TYPEID {

			/*
				formal is made up of identifier and the colon, followed 
				by its' type. We need to create a formal object using 
				the constructor.
			*/

			  $$ = formal($1,$3);

		};

	expression :

		/*
			There are many number of definitions for expressions are
			those are defined here.(all definitions are at 17th page 
			in cool-manual.pdf)
		*/ 

    OBJECTID ASSIGN expression {

      /*
        expression can be an assignment
      */

        $$ = assign($1,$3);

    } |

    expression '.' OBJECTID '(' expr_parameters ')'{

      /*
        this can be considered as a dispatch operation.
        We need to use the dispatch constructor to create
        a new dispatch instance as stated in the line 325 in 
        cool-tree.h
      */

        $$ = dispatch($1,$3,$5);

    } |

    expression '@' TYPEID '.' OBJECTID '(' expr_parameters ')'{

      /*
        this can be considered as a dispatch operation.
        Since we specially specfy the type here, 
        it works as a static dispatch operation.
        We need to create a static dispacth operation using
        the constructor as given in the line 300 in cool-tree.h.
      */

        $$ = static_dispatch($1,$3,$5,$7);

    } |

    OBJECTID '(' expr_parameters ')' {

      /*
        another type of dispatch operation.
        These type of dispatch operations comes
        from dropping the self keyword. Therefore
        we need to add that when we create a dispatch
        operation from the constructor.
      */

        $$ = dispatch(object(idtable.add_string("self")),$1,$3);

    } |

    IF expression THEN expression ELSE expression FI {

      /*
        this is a if then else condition, and we need to create
        a new condition using the constructor.
      */

        $$ = cond($2,$4,$6);

    } |

    WHILE expression LOOP expression POOL {

      /*
        We need to create a new loop instance for this
        using the constructor of the loop class.
      */

        $$ = loop($2,$4);

    } |

    '{' expr_statements '}' {

      /*
        these are the block of statements which are inside 
        curly braces.
      */

        $$ = block($2);

    } |

    LET expr_let{

      /*
        there are few types of token arrangements for the let
        keywords. But it is specified in the pdf, that let keyword
        contains the ambiguity issue. Therefore, cases for let keyword
        will be handled below in another section.
      */

      $$ = $2;

    } |

    CASE expression OF expr_case ESAC{

      /*
        since it helps with readability, all of the expressions 
        related to cases will be defined below.
      */

        $$ = typcase($2,$4);

    } |

    NEW TYPEID {

      /*
        Creating an instance using an object.
        We need to create an object for the given class.
        For this , we need to use the constructor for the 
        new class.
      */

        $$ = new_($2);

    } |

    ISVOID expression {

      /*
        We need to create a new isvoid instace using 
        the constructor for this.
      */

        $$ = isvoid($2);

    } |

    expression '+' expression {

      /*
        this is adding two expressions
      */

        $$ = plus($1,$3);

    } |

    expression '-' expression {

      /*
        this is substracting two expressions
      */

        $$ = sub($1,$3);

    } |

    expression '*' expression {

      /*
        this is multiplying two expressions
      */

        $$ = mul($1,$3);

    } |

    expression '/' expression {

      /*
        this is dividing two expressions
      */

        $$ = divide($1,$3);

    } |

    '~' expression {

      /*
        this is negating the expression
      */

        $$ = neg($2);

    } |

    expression '<' expression {

      /*
        this is the comparison operation to see
        if first expression is less than to the
        second one 
      */

        $$ = lt($1,$3);

    } |

    expression LE expression {

      /*
        this is the comparison operation to see
        if first expression is less or equal to the
        second one 
      */

        $$ = leq($1,$3);

    } |

    expression '=' expression {

      /*
        this is the comparison operation to see
        if first expression is equal to the
        second one 
      */

        $$ = eq($1,$3);

    } |

    NOT expression {

      /*
        This is to get the complement of an expression.
      */

        $$ = comp($2);

    } |

    '(' expression ')' {

      /*
        This is for expressions within brackets.
      */

        $$ = $2;

    } |

    OBJECTID {

      /*
        One object id is considered as a expression itself.
      */

        $$ = object($1);

    } |

    INT_CONST {

      /*
        integer value itself, can be considered as a expression.
      */

        $$ = int_const($1);

    } |

    STR_CONST {

      /*
        string value itself, can be considered as a expression.
      */

        $$ = string_const($1);

    } |

    BOOL_CONST {

      /*
        boolean value itself, can be considered as a expression.
      */

        $$ = bool_const($1);

    };

  expr_parameters :

    /*
      Definition of the list of parameters of expressions
    */

    expression {

        /* 
          expr_parameters can be made up of only one expression. 
          Here expression needs to be defined below.
        */

        /* 
          make a single expression instance using the constructor
        */
          $$ = single_Expressions($1);

    } | 

    expr_parameters ',' expression {  

        /*
          expr_parameters can be multilple expressions of parameters
        */

        /* 
          create a new single expression using constructor and append that
          to the parameter list
        */

          $$ = append_Expressions($1,single_Expressions($3));

    } |

    {
        /*
          Parameters also can be empty
        */
          $$ = nil_Expressions();

    };

  expr_statements :

  /*
    This is the expressions in a block
  */

    expression ';' {

        /*
          expr_parameters can be made up of only one expression. 
          Here expression needs to be defined below.
        */

        /*
          make a single expression instance using the constructor 
        */
          $$ = single_Expressions($1);

    } | 

    expr_statements expression ';' {  

        /*
          expr_parameters can be multilple expressions of parameters
        */

        /*
          create a new single expression using constructor and append that 
          to the parameter list
        */
          $$ = append_Expressions($1,single_Expressions($2));

    } | 

    error ';' { 

      /*  
        When there is an error in the statements, it is identified and
        then , discard the current lookahead token. This is useful 
        primarily in error rules and apply a null node to the parse tree.
      */ 

        yyclearin;
        $$ = NULL;

    };

  expr_case :

    /*
      this is the expressions for the switch case statements
    */

    single_case {

      /*
        one case related to the switch case structure
      */

      $$ = single_Cases($1);

    } |

    expr_case single_case{

      /*
        append the new case to the list
      */

      $$ = append_Cases($1,single_Cases($2));

    };

  single_case :

    /*
      Here we define single case for the expr_case
    */ 

    OBJECTID ':' TYPEID DARROW expression ';' {

      /*
        this is the structure for a single case
      */

      $$ = branch($1,$3,$5);

    };

  expr_let : 

    /*
      definitions for expressions in let
    */

    OBJECTID ':' TYPEID IN expression {

      /*
        without both the first and second optional parts
      */

      $$ = let($1,$3,no_expr(),$5);

    } |

    OBJECTID ':' TYPEID ASSIGN expression IN expression {

      /*
        without the second optional part
      */

      $$ = let($1,$3,$5,$7);
      
    } |

    OBJECTID ':' TYPEID ',' expr_let{

      /*
        without the first optional part
      */

      $$ = let($1,$3,no_expr(),$5);
      
    } |

    OBJECTID ':' TYPEID ASSIGN expression ',' expr_let {

      /*
        with all optional parts
      */

      $$ = let($1,$3,$5,$7);
      
    } |

    error IN expression {

      /*
        When there is an error in the object id definition, it is 
        identified and then , discard the current lookahead token. This is
        useful primarily in error rules and apply a null node to the parse 
        tree.
      */

        yyclearin; 
        $$ = NULL;

    } |

    error ',' expr_let {

      /*
        When there is an error in the object id definition with the
        assign operation, it is identified and then , discard the current 
        lookahead token. This is useful primarily in error rules and apply
        a null node to the parse tree.
      */

        yyclearin;
        $$ = NULL;
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
      