-- Group 12 (E/17/027,E/17/219)
-- 1. erroneous class definition ('inherits' is misspelled)
Class Book inherit IO{

    -- 2. erroneous statement definition (semicolon missing)
    title : String
    author : String;

    -- 3. erroneous type declaration (colon missing)
    initBook(title_p : String, author_p : String) : Book {
        {
            title <- title_p;
            author <- author_p;
            self;
        }
    };
};

-- 4. both class def and statements are erroneous (misspelling and semicolon)
Class Article inherit Book {
    per_title : String
};

Class BookList inherits IO {

    -- 5. incorrect feature definition (colon missing)
    isNil() Bool { { abort(); true; } };

    cons(hd : Book) : Cons {
	-- 6. erroneous 'let' statement (assignment missing)
        (let new_cell : Cons new Cons in
            new_cell.init(hd,self)
        )
    };

    cons(hd : Book) : Cons {
	-- 7. erroneous 'let' statement ('new' missing)
        (let new_cell : Cons <- Cons in
            new_cell.init(hd,self)
        )
    };
};

Class Cons inherits BookList {

    print_list() : Object {
        {
            case xcar.print() of
		-- 8. incorrect 'case' expression (darrow missing)
                dummy : Book out_string("- dynamic type was Book -\n");
                dummy : Article => out_string("- dynamic type was Article -\n");
            esac;
            xcdr.print_list();
        }
    };
};
