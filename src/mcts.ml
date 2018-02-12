let _beta = 1.

type 'a tree = {
  state : 'a ;
  mutable q : float ;
  mutable n : int ;
  mutable children : 'a tree list
}

let make_node state =
  {
  state = state ;
  q = 0. ;
  n = 0 ;
  children = []
}

let get_state node = node.state

let print_node n =
  Printf.printf "%d\n" (List.length n.children)

(* Contains ways to select final best path *)
module Win_pol = struct

  (* arbitrary cste given by chaslot *)
  let _a = 4.

  (* define le low confidence bound *)
  let lcb node =
    node.q +. _a /. sqrt (float node.n +. 1.)

  (* some functions that define how to select the final path
    (best q, best n of best lcb)*)
  let cmp_max n1 n2 =
    if n1.q < n2.q then n2 else n1

  let cmp_robust n1 n2 =
  if n1.n < n2.n then n2 else n1

  let cmp_secure n1 n2 =
    if lcb n1 < lcb n2 then n2 else n1

  (*********)

  (* Select the child with highest reward *)
  let max children =
    Auxfct.argmax cmp_max children

  (* Select the most visited child *)
  let robust children =
    Auxfct.argmax cmp_robust children

  (* Select the child which maximises a lower confidence bound *)
  let secure children =
    Auxfct.argmax cmp_secure children
end

(* Selection policy *)
module Sel_pol = struct
  (* TODO: add single player mcts 3rd term *)
  let ucb beta father child =
    child.q /. float child.n +.
    beta *. sqrt (2. *. log (float father.n) /. (float child.n))

  let best_child t =
    let cmp_ucb ta tb =
      if ucb _beta t ta >= ucb _beta t tb then ta else tb
    in
    Auxfct.argmax cmp_ucb t.children
end

(* Temporary considering functor approach *)
(* let dummystate = Airconf.dummy *)

let random_elt lst =
  List.nth lst (Random.int (List.length lst))

(* [produce t] creates the list of reachable nodes from [t] *)
    (* Functor should create the produce rule *)
let produce t =
  let states = Airconf.produce t.state in
  List.map (fun s -> { state = s ; q = 0. ; n = 0 ; children = [] }) states

(** [force_deploy t] tries to add children from a production rule *)
let force_deploy t =
  match t.children with
  | [] -> t.children <- produce t
  | _ :: _ -> ()

(* TODO The two functions below could be grouped in one which would expand the
 * node or raise an exception *)
let expandable t =
  (* Parses the children to see if one has not been visited *)
  let rec loop = function
    | [] -> false
    | hd :: tl -> if hd.n = 0 then true else loop tl
  in
  if Airconf.terminal t.state then false else loop t.children

(** [expand t] returns node which must be visited among children of [t] *)
let expand t =
  let rec loop = function
    | [] -> failwith "no nodes to expand"
    | hd :: tl ->
        if hd.n = 0 then hd else loop tl
  in
  loop t.children

(** [select t a] builds a path toward most urgent node to expand *)
    (* TODO see above comment considering expand *)
let rec select tree ancestors =
  force_deploy tree ;
  if expandable tree then tree :: ancestors
  else
    match tree.children with
    | (hd :: tl) -> let favourite = Sel_pol.best_child tree in
        select favourite (tree :: ancestors)
    | [] -> ancestors

let treepolicy root =
  let path = select root [] in
  let exnode = expand (List.hd path) in
  exnode :: path

(** [simulate t] parses the tree [t] randomly until a terminal state is found,
    and returnsan evaluation of the path *)
let simulate t =
  let rec loop lt acc =
    let cost = Airconf.conf_cost lt.state in
    if Airconf.terminal lt.state then cost +. acc
    else
      let children = produce lt in
      let randchild = random_elt children in
      loop randchild (acc +. cost)
  in
  loop t 0.

(** [defaultpolicy n] gives a list of the result of [_nsim] simulations *)
let defaultpolicy tree nsim =
  let rec loop cnt acc =
    if cnt > nsim then acc
    else loop (cnt + 1) (simulate tree :: acc)
  in
  loop 0 []

(** [backpropagate a w] updates ancestors [a] with the result win [w] *)
let rec backpropagate (ancestors : 'a tree list) reward =
  match ancestors with
  | [] -> ()
  | hd :: tl ->
      begin
        hd.q <- hd.q +. reward ;
        hd.n <- succ hd.n ;
        backpropagate tl reward
      end

(** [mcts r] updates tree of root [t] with monte carlo *)
let mcts root nsim =
  let flag = ref false in
  while not !flag do
  (* for i = 1 to 15 do *)
    let path = treepolicy root in
    let wins = defaultpolicy (List.hd path) nsim in
    let bppg_aux win = backpropagate path win in
    List.iter bppg_aux wins;
    flag := Airconf.terminal (get_state (List.hd path));
    Printf.printf "%02d %d\n" (Airconf.get_time (get_state (List.hd path)))
      (List.length (List.hd path).children)
  done

let best_path root criterion =
  let rec aux current_node accu =
    match current_node.children with
    | [] -> accu
    | _ -> let best_ch = criterion current_node.children in
      (aux best_ch (best_ch::accu) )
  in
  aux root [root]

let best_path_max root nsim =
  mcts root nsim;
  best_path root Win_pol.max

let best_path_secure root nsim =
  mcts root nsim;
  best_path root Win_pol.secure

let best_path_robust root nsim =
  mcts root nsim;
  best_path root Win_pol.robust
