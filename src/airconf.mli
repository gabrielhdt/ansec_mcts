(** Functorial interface to manipulate airspace configuration. Takes as input
    a traffic forecasting module *)

(** Type of the traffic forecasting module *)
module type WLS = sig

  (** Horizon of the forecast, will determine the depth of the tree *)
  val tmax : int

  (** [f t m] returns a forecasted load for sector [m] at time [t] *)
  val f : int -> string -> int
end

(** Output signature f the functor *)
module type S = sig
  (** Specification of a configuration *)
  type t

  (** Prints specs of a partitioning *)
  val print : t -> unit

  (** [reward c] gives the reward associated to config [c], based on
      miscellaneous parameters such as number of flights *)
  val reward : t -> float

  (** [produce t] returns all feasible configurations from configuration [t] *)
  val produce : t -> t list

  (** [terminal t] asserts whether a configuration [t] is the last to be
      considered *)
  val terminal : t -> bool

  (** [make_root c] creates a new configuration for a given partition [c] *)
  val make_root : (Util.Sset.t * Util.Smap.key list) list -> t

  (****************************** DEBUG **************************************)
  val get_partitions : t -> (Util.Sset.t * Util.Smap.key list) list
  val get_time : t -> int
end

module Make : functor (Workload : WLS) -> S
