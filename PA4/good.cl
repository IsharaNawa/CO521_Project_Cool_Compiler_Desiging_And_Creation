class Main inherits IO{

	x: Int;
	y: String;
	f: Foo;

	z: Bool;

	main(): Object {{

		x <- 3; x <- 5; y <- "test"; f <- new Foo;

		isvoid true; isvoid false; isvoid x;

		let x:Int <- 5 in x;
      	}};

 	foo(): String {"test"};

	a : A;
    	b : B;
};

class Foo {
 	x:Int <- 3;
};

class A {
	foo:Int;
	main() : Int { 6 };
};

class B inherits A {
	bar:Int;
};

class C {
	func():Int { { self; "hello"; true; 1; } };
};
