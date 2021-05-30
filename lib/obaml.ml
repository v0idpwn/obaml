open PGOCaml;;
(* TODO: open Base, requires fixing pgocaml_ppx so it supports module shadowing *)

(* Interface *)
module type Oban_worker = sig
  val perform : Job.t -> Job_result.t
end

module type Oban_impl = sig
  val to_worker : string -> (module Oban_worker)
  val queue : string
end

let perform_job impl (job : Job.t) : Job_result.t =
  let module Impl = (val impl : Oban_impl) in
  let module Worker = (val Impl.to_worker job.worker : Oban_worker) in
  Worker.perform job

(* TODO: discard when exceeding attempts *)
(* TODO: error should be stored as jsonb *)
let ack_result dbh (result : Job_result.t) : unit =
  match result with
  | Ok job -> Query.complete_job dbh job.id
  | Error (job, reason) -> Query.error_job dbh job.id reason

(* Sample implementation example *)
module My_worker_a : Oban_worker = struct
  let perform job = Job_result.ok job
end

module My_worker_b : Oban_worker = struct
  let perform job = Job_result.error job "always fail"
end

module My_impl : Oban_impl = struct
  let to_worker (name : string) =
    match name with
    | "Elixir.MyApp.MyWorkerA" -> (module My_worker_a : Oban_worker)
    | "Elixir.MyApp.MyWorkerB" -> (module My_worker_b : Oban_worker)
    | _ -> (module My_worker_b : Oban_worker)

  let queue = "default"
end

(* Runtime example *)
let () =
  let dbh = connect () in
  let jobs = Query.fetch_jobs dbh My_impl.queue 1L in
  let results = List.map (perform_job (module My_impl)) jobs in
  let _ = List.map (ack_result dbh) results in
  PGOCaml.close(dbh)
