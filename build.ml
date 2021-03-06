let start = Unix.gettimeofday ();;
open List;;
open Typs;;
open Utils;;
open State;;
open Helpers;;

let jobs, targets, dodeplist, dotarlist = getopt ();;

let get key msg =
  match getval key with | None -> failwith msg | Some s -> s
;;

let getdef key def =
  match getval key with | None -> def | Some s -> s
;;

let srcdir = get "src" "no source dir";;
let cc = getdef "cc" "cc";;
let ccopt = getdef "ccopt" "";;

let boc flags src =
  let o = src ^ ".o" in
  let c = src ^ ".c" in
  ocaml
    "ocamlc.opt"
    ("-cc '" ^ cc ^ "' -ccopt '" ^ flags ^ " " ^ ccopt ^ " -o " ^ o ^ "'")
    o
    (StrSet.singleton o)
    [Filename.concat srcdir c]
    (
      if src = "skin" || src = "skinvp"
      then
        (StrSet.add (Filename.concat srcdir "pgl.h")
            (StrSet.singleton (Filename.concat srcdir "vec.c")))
      else StrSet.empty
    )
  ;
;;

let bso name objs =
  let so = name ^ ".so" in
  (* let so = Filename.concat (Sys.getcwd ()) so in *)
  let o = List.map (fun s -> s ^ ".o") objs in
  ocaml
    cc
    ("-shared -o " ^ so)
    so
    (StrSet.singleton so)
    o
    StrSet.empty
  ;
  so
;;

let _ =
  List.iter (fun src ->
    cmopp ~flags:"-g -I +lablGL -thread" ~dirname:srcdir src)
    ["xff"; "nto"; "nmo"; "slice"; "rend"; "vec"; "skb"; "qtr"; "anb"
    ;"skin"; "imgv"]
  ;
  boc "-g" "swizzle";
  boc "-g" "skin";
  boc "-g" "skinvp";
  let so = bso "swizzle" ["swizzle"] in
  let so1 = bso "skin"  ["skin"; "skinvp"] in
  let prog name cmos =
    ocaml
      "ocamlc.opt"
      ("-g -I +lablGL lablgl.cma lablglut.cma unix.cma -dllpath " ^ Sys.getcwd ())
      name
      (StrSet.singleton name)
      (State.dep_sort cmos)
      StrSet.empty
  in
  prog "dormin" ["slice.cmo"; "xff.cmo"; "nto.cmo"; "skin.cmo"; "rend.cmo";
                 "vec.cmo"; "anb.cmo"; "skb.cmo"; "nmo.cmo"; "qtr.cmo";
                 so; so1];
  prog "imgv" ["slice.cmo"; "xff.cmo"; "nto.cmo"; "imgv.cmo"; so; so1];
  ()
;;

let () =
  Helpers.run start jobs targets dodeplist dotarlist
;;
