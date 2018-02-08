(** Basic scenario generator, uses a json file.
    Each sector has a workload defined by the number of aircraft in it. *)

(** A scenario *)
type t

(** [load s] loads file whose path is [s] into a scenario *)
val load : string -> t

(** [f s t u] @returns a value used to compute the workload of sector [u] at
    time [t] for scenario [s] *)
val f : t -> int -> string -> int