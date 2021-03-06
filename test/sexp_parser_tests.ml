open! Core
open OUnit2
open L2
open Tests_common
open Ast
open Infer

let n = Name.of_string

let test_parse_expr =
  let open Tree in
  make_tests ~in_f:Expr.of_string_exn ~out_f:Fun.id ~in_str:Fun.id
    ~out_str:Expr.to_string ~res_str:Expr.to_string "parse_expr"
    [
      ("1", `Num 1);
      ("#t", `Bool true);
      ("#f", `Bool false);
      ("[]", `List []);
      ("[1]", `List [ `Num 1 ]);
      ("[1 2]", `List [ `Num 1; `Num 2 ]);
      ("[[]]", `List [ `List [] ]);
      ("[[1]]", `List [ `List [ `Num 1 ] ]);
      ("a", `Id (n "a"));
      ("test", `Id (n "test"));
      ("(+ (+ 1 2) 3)", `Op (Plus, [ `Op (Plus, [ `Num 1; `Num 2 ]); `Num 3 ]));
      ( "(let f (lambda (x) (if (= x 0) 0 (+ (f (- x 1)) 1))) (f 0))",
        `Let
          ( n "f",
            `Lambda
              ( [ n "x" ],
                `Op
                  ( If,
                    [
                      `Op (Eq, [ `Id (n "x"); `Num 0 ]);
                      `Num 0;
                      `Op
                        ( Plus,
                          [
                            `Apply
                              (`Id (n "f"), [ `Op (Minus, [ `Id (n "x"); `Num 1 ]) ]);
                            `Num 1;
                          ] );
                    ] ) ),
            `Apply (`Id (n "f"), [ `Num 0 ]) ) );
      ("(+ 1 2)", `Op (Plus, [ `Num 1; `Num 2 ]));
      ("(cons 1 [])", `Op (Cons, [ `Num 1; `List [] ]));
      ("(cons 1 [2])", `Op (Cons, [ `Num 1; `List [ `Num 2 ] ]));
      ("(cdr [])", `Op (Cdr, [ `List [] ]));
      ("(cdr [1 2])", `Op (Cdr, [ `List [ `Num 1; `Num 2 ] ]));
      ("(f 1 2)", `Apply (`Id (n "f"), [ `Num 1; `Num 2 ]));
      ( "(> (f 1 2) 3)",
        `Op (Gt, [ `Apply (`Id (n "f"), [ `Num 1; `Num 2 ]); `Num 3 ]) );
      ("(map x7 f6)", `Apply (`Id (n "map"), [ `Id (n "x7"); `Id (n "f6") ]));
      ("{}", `Tree Empty);
      ("{1}", `Tree (Node (`Num 1, [])));
      ("{1 {}}", `Tree (Node (`Num 1, [ Empty ])));
    ]

let test_parse_typ =
  make_tests ~in_f:Type.of_string_exn ~out_f:Fun.id ~in_str:Fun.id
    ~out_str:Type.to_string ~res_str:Type.to_string "parse_typ"
    [ ("num", Const_t Num_t) ]

let test_parse_example =
  make_tests ~in_f:Example.of_string_exn ~out_f:Fun.id ~in_str:Fun.id
    ~out_str:Example.to_string ~res_str:Example.to_string "parse_example"
    [
      ("(f 1) -> 1", (`Apply (`Id (n "f"), [ `Num 1 ]), `Num 1));
      ( "(f (f 1)) -> 1",
        (`Apply (`Id (n "f"), [ `Apply (`Id (n "f"), [ `Num 1 ]) ]), `Num 1) );
      ("(f []) -> []", (`Apply (`Id (n "f"), [ `List [] ]), `List []));
    ]

let tests =
  "sexp-parser-tests" >::: [ test_parse_expr; test_parse_typ; test_parse_example ]
