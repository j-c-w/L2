open Core
open Collections

type status = { synthesis : Counter.t; hashcons : Counter.t }

let logo_lines =
  [
    "                            .lkO0K0xc.  ";
    "                          'kk;.  .;kWXc ";
    "                         .NN,       kMMo";
    "                         'WMWx      kMMk";
    "                          ;dkc     lWMX,";
    "         .:loc.                  .OMWx. ";
    "       .okcdWMN,               .oXOc.   ";
    "      .0o   kMM0             .xNk'    ';";
    "      .'    lMMN.          .cOl.     .KO";
    "            ;MMM,         lXWOddddddx0Md";
    "            oMMM:        ;kkkkkkkkkkkkk,";
    "          .ONWMMl                       ";
    "         'XO.0MMo                       ";
    "        ,Ko  OMMx                       ";
    "      .xNc   xMMO                       ";
    "     ;NK,    dMM0                       ";
    "   .dNd.     lMMX.   ..                 ";
    "  ;XMo       :MMM'  ,O.                 ";
    " dWNl        .NMMOlxd.                  ";
    "lKO:          ;KMNx.                    ";
  ]

let status_lines =
  let status =
    [
      "";
      "SynthesizingDOTS";
      "";
      "Hypotheses verified: NUM_HYPOS";
      "   Hypotheses saved: NUM_SAVED";
      "";
      "Memoization table hit rate: HIT_RATE";
      "";
      "Signatures: SIGS_NONE none, SIGS_CHECKED checked, SIGS_DUP dups, SIGS_FAIL \
       fails";
    ]
  in
  status @ List.init (List.length logo_lines - List.length status) ~f:(fun _ -> "")

let escape esc =
  let suffix = function
    | `Save_cursor -> "7"
    | `Restore_cursor -> "8"
    | `Clear_cursor_down -> "[0J"
    | `Clear_entire_screen -> "[2J"
    | `Cursor_upper_left -> "[H"
    | `Reset -> "c"
  in
  let prefix = "\027" in
  prefix ^ suffix esc

let enabled = ref true

let enable : unit -> unit = fun () -> enabled := true

let disable : unit -> unit = fun () -> enabled := false

let print_status : status -> unit =
  let last_print = ref Time.epoch in
  let tick = ref 0 in
  fun status ->
    if !enabled then
      let diff = Time.diff (Time.now ()) !last_print in
      if Time.Span.( > ) diff (Time.Span.of_ms 2000.0) then (
        incr tick;
        last_print := Time.now ();
        let dots = [ ""; "."; ".."; "..." ] in
        let hits = Counter.get status.synthesis "hole_hits" in
        let misses = Counter.get status.synthesis "hole_misses" in
        let rate = Float.of_int hits /. Float.of_int (hits + misses) *. 100.0 in
        let subs =
          [
            ("NUM_HYPOS", Int.to_string (Counter.get status.synthesis "num_hypos"));
            ( "NUM_SAVED",
              Int.to_string (Counter.get status.synthesis "num_saved_hypos") );
            ("HIT_RATE", Float.to_string_hum ~decimals:2 rate);
            ( "SIGS_CHECKED",
              Int.to_string (Counter.get status.synthesis "sigs_checked") );
            ("SIGS_DUP", Int.to_string (Counter.get status.synthesis "sigs_dup"));
            ("SIGS_FAIL", Int.to_string (Counter.get status.synthesis "sigs_fail"));
            ("SIGS_NONE", Int.to_string (Counter.get status.synthesis "sigs_none"));
            ("DOTS", List.nth_exn dots (!tick % List.length dots));
          ]
        in
        print_string (escape `Cursor_upper_left);
        print_string (escape `Reset);
        List.zip_exn logo_lines status_lines
        |> List.iter ~f:(fun (logo, status_line) ->
               let status_line =
                 List.fold subs ~init:status_line ~f:(fun line (pattern, with_) ->
                     String.substr_replace_first line ~pattern ~with_)
               in
               print_string logo;
               print_string "   ";
               print_string status_line;
               Out_channel.newline stdout);
        Out_channel.flush stdout )
