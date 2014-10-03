open Core.Std
open Printf

let catamorphic_solve_testcases =
  [
    (* "compress", *)
    (* [ *)
    (*   "(compress []) -> []"; *)
    (*   "(compress [1]) -> [1]"; *)
    (*   "(compress [1 1 1]) -> [1]"; *)
    (*   "(compress [1 2 1]) -> [1 2 1]"; *)
    (*   "(compress [1 2 2 1]) -> [1 2 1]"; *)
    (*   "(compress [1 2 2 1 1 4 4]) -> [1 2 1 4]"; *)
    (*   "(compress [1 1 1 1 1 2 2 2 2 1 1 4 4]) -> [1 2 1 4]"; *)
    (* ]; *)

    "dupli",
    [
      "(dupli []) -> []";
      "(dupli [1]) -> [1 1]";
      "(dupli [1 2 3]) -> [1 1 2 2 3 3]";
    ];

    "car",
    ["(mycar [0]) -> 0";
     "(mycar [1 0]) -> 1";
     "(mycar [2 1 0]) -> 2";
    ];

    "cdr",
    ["(mycdr [0]) -> []";
     "(mycdr [1 0]) -> [0]";
     "(mycdr [2 1 0]) -> [1 0]";
    ];

    "value",
    ["(myvalue {1}) -> 1";
     "(myvalue {2 {} {}}) -> 2"
    ];

    "incr",
    ["(incr []) -> []";
     "(incr [1]) -> [2]";
     "(incr [1 2]) -> [2 3]";
     "(incr [1 2 3 4]) -> [2 3 4 5]";
    ];

    "incrt",
    ["(incrt {}) -> {}";
     "(incrt {1}) -> {2}";
     "(incrt {1 {2}}) -> {2 {3}}";
    ];

    "incrs",
    ["(incrs []) -> []";
     "(incrs [[1]]) -> [[2]]";
     "(incrs [[1] [2]]) -> [[2] [3]]";
     "(incrs [[1 2] [3 4]]) -> [[2 3] [4 5]]";
    ];

    "sumt",
    ["(sumt {}) -> 0";
     "(sumt {1}) -> 1";
     "(sumt {1 {2} {3}}) -> 6";
    ];

    "flatten",
    ["(join []) -> []";
     "(join [[] [1 0]]) -> [1 0]";
     "(join [[1 0] []]) -> [1 0]";
     "(join [[1 0] [2 3] [6] [4 5]]) -> [1 0 2 3 6 4 5]";

     "(flatten {}) -> []";
     "(flatten {1}) -> [1]";
     "(flatten {1 {2} {3}}) -> [1 2 3]";
    ];

    "add",
    ["(add [] 1) -> []";
     "(add [1] 1) -> [2]";
     "(add [1 2] 1) -> [2 3]";
     "(add [1 2] 2) -> [3 4]";
     "(add [1 2 3 4] 5) -> [6 7 8 9]";
    ];

    "evens",
    ["(evens []) -> []";
     "(evens [1]) -> []";
     "(evens [1 2]) -> [2]";
     "(evens [1 2 3 4]) -> [2 4]";
     "(evens [5 6 3 9 8 4]) -> [6 8 4]";
    ];

    "zeroes",
    ["(zeroes []) -> []";
     "(zeroes [0]) -> []";
     "(zeroes [1 0]) -> [1]";
     "(zeroes [1 0 2]) -> [1 2]";
    ];

    "concat",
    ["(concat [] []) -> []";
     "(concat [0] []) -> [0]";
     "(concat [1 0] [0]) -> [1 0 0]";
     "(concat [1 0 2] [3 4]) -> [1 0 2 3 4]";
    ];

    "sums",
    ["(sums []) -> []";
     "(sums [[]]) -> [0]";
     "(sums [[1] []]) -> [1 0]";
     "(sums [[1 2] [3 4]]) -> [3 7]";
    ];

    "reverse",
    ["(reverse []) -> []";
     "(reverse [0]) -> [0]";
     "(reverse [0 1]) -> [1 0]";
     "(reverse [0 1 2]) -> [2 1 0]"
    ];

    "last",
    ["(last [1]) -> 1";
     "(last [1 2]) -> 2";
     "(last [1 2 3]) -> 3";
     "(last [1 3 5 8]) -> 8"
    ];

    "length",
    ["(length []) -> 0";
     "(length [0]) -> 1";
     "(length [0 0]) -> 2";
     "(length [0 0 0]) -> 3";
    ];

    "join",
    ["(join []) -> []";
     "(join [[] [1 0]]) -> [1 0]";
     "(join [[1 0] []]) -> [1 0]";
     "(join [[1 0] [2 3] [6] [4 5]]) -> [1 0 2 3 6 4 5]";
    ];

    (* "count", *)
    (* ["(count [] 1) -> 0"; *)
    (*  "(count [1 0] 1) -> 1"; *)
    (*  "(count [0 0 1] 0) -> 2"; *)
    (*  "(count [1 2 2 2 4 4 5] 2) -> 3"; *)
    (*  "(count [1 2 2 2 4 4 5] 4) -> 2"; *)
    (*  "(count [1 2 2 2 4 4 5] 5) -> 1"; *)
    (* ]; *)

    "max",
    [
      "(max []) -> 0";
      "(max [0]) -> 0";
      "(max [0 2 1]) -> 2";
      "(max [1 6 2 5]) -> 6";
      "(max [1 6 7 5]) -> 7";
      "(max [10 25 7 9 18]) -> 25";
      "(max [100 25 7 9 18]) -> 100";
    ];

    "height",
    [
      "(max []) -> 0";
      "(max [0]) -> 0";
      "(max [0 2 1]) -> 2";
      "(max [1 6 2 5]) -> 6";
      "(max [1 6 7 5]) -> 7";
      "(max [10 25 7 9 18]) -> 25";
      "(max [100 25 7 9 18]) -> 100";

      "(height {}) -> 0";
      "(height {1}) -> 1";
      "(height {100 {100} {100}}) -> 2";
      "(height {100 {100} {100 {100 {100}}}}) -> 4";
      "(height {100 {100 {100 {100 {100}}}} {100}}) -> 5";
      "(height {90 {6 {5} {6} {8}} {7} {9} {5}}) -> 3";
    ];

    (* ("cprod", ["(f []) -> [[]]"; *)
    (*            "(f [[]]) -> []"; *)
    (*            "(f [[] []]) -> []"; *)
    (*            "(f [[1 2 3] [4] [5 6]]) -> [[1 4 5] [1 4 6] [2 4 5] [2 4 6] [3 4 5] [3 4 6]]"; *)
    (*           ], []), *)
    (* ""; *)


    (* ("power", ["(f []) -> [[]]"; *)
    (*            "(f [0]) -> [[] [0]]"; *)
    (*            "(f [0 1]) -> [[] [1] [0] [0 1]]"; *)
    (*           ], []), *)
    (* ""; *)

    "multfirst",
    ["(multfirst []) -> []";
     "(multfirst [1 0]) -> [1 1]";
     "(multfirst [0 1 0]) -> [0 0 0]";
     "(multfirst [2 0 2 3]) -> [2 2 2 2]";
    ];

    "multlast",
    ["(multlast []) -> []";
     "(multlast [1 0]) -> [0 0]";
     "(multlast [0 1 0]) -> [0 0 0]";
     "(multlast [2 0 2 3]) -> [3 3 3 3]";
    ];

    "append",
    ["(append [] 1) -> [1]";
     "(append [] 2) -> [2]";
     "(append [1 0] 2) -> [1 0 2]";
    ];

    "average",
    ["(sum []) -> 0";
     "(sum [1]) -> 1";
     "(sum [1 2 3]) -> 6";
     "(sum [1 1 1 1]) -> 4";
     "(length []) -> 0";
     "(length [0]) -> 1";
     "(length [0 0]) -> 2";
     "(length [0 0 0]) -> 3";
     "(average [0]) -> 0";
     "(average [0 1 5]) -> 2";
     "(average [1 1 1 1]) -> 1";
     "(average [4 5 7 8]) -> 6";
    ];

    "dropaverage",
    ["(sum []) -> 0";
     "(sum [1]) -> 1";
     "(sum [1 2 3]) -> 6";
     "(sum [1 1 1 1]) -> 4";
     "(length []) -> 0";
     "(length [0]) -> 1";
     "(length [0 0]) -> 2";
     "(length [0 0 0]) -> 3";
     "(average [0]) -> 0";
     "(average [0 1 5]) -> 2";
     "(average [1 1 1 1]) -> 1";
     "(average [4 5 7 8]) -> 6";
     "(dropaverage [0 1 5]) -> [5]";
     "(dropaverage [1 1 1 1]) -> [1 1 1 1]";
     "(dropaverage [4 5 7 8]) -> [7 8]";
    ];

    "dropmax",
    [
      "(max []) -> 0";
      "(max [0]) -> 0";
      "(max [0 2 1]) -> 2";
      "(max [1 6 2 5]) -> 6";
      "(max [1 6 7 5]) -> 7";
      "(max [10 25 7 9 18]) -> 25";
      "(max [100 25 7 9 18]) -> 100";
      "(dropmax [3 5 2]) -> [3 2]";
      "(dropmax [3 1 2]) -> [1 2]";
      "(dropmax [1 5 2]) -> [1 2]";
    ];

    "shiftl",
    ["(append [] 1) -> [1]";
     "(append [] 2) -> [2]";
     "(append [1 0] 2) -> [1 0 2]";

     "(shiftl []) -> []";
     "(shiftl [1]) -> [1]";
     "(shiftl [1 2]) -> [2 1]";
     "(shiftl [5 2 3]) -> [2 3 5]";
     "(shiftl [1 2 3 4]) -> [2 3 4 1]";
    ];

    "shiftr",
    [
      "(last [1]) -> 1";
      "(last [1 0]) -> 0";
      "(last [1 0 5]) -> 5";
      
      "(shiftr []) -> []";
      "(shiftr [1]) -> [1]";
      "(shiftr [1 2]) -> [2 1]";
      "(shiftr [1 2 3]) -> [3 1 2]";
      "(shiftr [1 2 3 4]) -> [4 1 2 3]";
      "(shiftr [1 9 7 4]) -> [4 1 9 7]";
    ];

    "member",
    ["(member [] 0) -> #f";
     "(member [0] 0) -> #t";
     "(member [0] 1) -> #f";
     "(member [0 1 0] 0) -> #t";
     "(member [0 1 0] 1) -> #t";
     "(member [1 6 2 5] 2) -> #t";
     "(member [5 6 2] 6) -> #t";
     "(member [1 2 5] 3) -> #f";
    ];
    
    "dedup",
    ["(member [] 0) -> #f";
     "(member [0] 0) -> #t";
     "(member [0] 1) -> #f";
     "(member [0 1 0] 0) -> #t";
     "(member [0 1 0] 1) -> #t";
     "(member [1 6 2 5] 2) -> #t";
     "(member [5 6 2] 6) -> #t";
     "(member [1 2 5] 3) -> #f";

     "(dedup []) -> []";
     "(dedup [1]) -> [1]";
     "(dedup [1 2 5]) -> [1 2 5]";
     "(dedup [1 2 5 2]) -> [1 5 2]";
     "(dedup [1 1 1 2 5 2]) -> [1 5 2]";
     "(dedup [3 3 3 5 5 5]) -> [3 5]";
     "(dedup [1 2 3 2 1]) -> [3 2 1]";
    ];
    

  (* ("insert", ["(f [] 1) -> [1]"; *)
  (*             "(f [] 2) -> [2]"; *)
  (*             "(f [0 1] 2) -> [0 1 2]"; *)
  (*             "(f [0 1] 1) -> [0 1 1]"; *)
  (*             "(f [0 1] 0) -> [0 0 1]"; *)
  (*             "(f [0 1 2] 0) -> [0 0 1 2]"; *)
  (*            ], ["[]"]), *)
  (* ""; *)

  (* ("drop", ["(f [] 0) -> []"; *)
  (*           "(f [1] 0) -> [1]"; *)
  (*           "(f [] 1) -> []"; *)
  (*           "(f [] 2) -> []"; *)
  (*           "(f [0 1] 0) -> [0 1]"; *)
  (*           "(f [0 1] 1) -> [1]"; *)
  (*           "(f [0 1] 2) -> []"; *)
  (*           "(f [1 1 1] 0) -> [1 1 1]"; *)
  (*           "(f [1 1 1] 1) -> [1 1]"; *)
  (*           "(f [1 1 1] 2) -> [1]"; *)
  (*           "(f [1 1 1] 3) -> []"; *)
  (*            ], ["[]"]), *)
  (* "(if (= 0 n) l (drop (cdr l) (- n 1)))"; *)

  (* ("frequency", ["(f [1]) -> [1]"; *)
  (*                "(f [1 2]) -> [1 1]"; *)
  (*                "(f [1 2 1]) -> [2 1 2]"; *)
  (*               ], ["0"]), *)
  (* ""; *)
  ]

let time_solve (name, example_strs) =
  let examples = List.map example_strs ~f:Util.parse_example in
  begin
    let start_time = Time.now () in
    let solutions = Search.solve examples in
    let end_time = Time.now () in
    let solve_time = Time.diff end_time start_time in
    let solutions_str =
      Util.Ctx.to_alist solutions
      |> List.map ~f:(fun (name, lambda) ->
                      let lambda = Expr.normalize lambda in
                      "\t" ^ (Expr.to_string (`Let (name, lambda, `Id "_"))))
      |> String.concat ~sep:"\n"
    in
    printf "Solved %s in %s. Solutions:\n%s\n\n"
           name
           (Time.Span.to_short_string solve_time)
           solutions_str;
    flush stdout;
  end

let () =
  printf "Running test cases...\n";
  List.iter catamorphic_solve_testcases ~f:time_solve
