open PGOCaml;;
(* TODO: open Base, requires fixing pgocaml_ppx so it supports module shadowing *)

(* Interface *)
module type Oban_worker = sig
  val perform : Job.t -> Job_result.t
  val backoff : Job.t -> int
end

module type Oban_impl = sig
  val to_worker : string -> (module Oban_worker)
  val queue : string
end

let perform_job impl (job : Job.t) : Job_result.t =
  let module Impl = (val impl : Oban_impl) in
  let module Worker = (val Impl.to_worker job.worker : Oban_worker) in
  Worker.perform job

(* TODO: error should be stored as jsonb *)
let ack_result dbh impl (result : Job_result.t) : unit =
  let module Impl = (val impl : Oban_impl) in
  match result with
  | Ok job -> Query.complete_job dbh job.id
  | Error (job, reason) -> 
      if job.attempt = job.max_attempts then
        Query.discard_job dbh job.id reason
      else
        let module Worker = (val Impl.to_worker job.worker : Oban_worker) in
        let backoff = Worker.backoff(job) in
        Query.error_job dbh job.id reason backoff
  | Discard (job, reason) -> Query.discard_job dbh job.id reason
  | Snooze (job, time) -> Query.snooze_job dbh job.id time


(* Default workers *)
module Default_workers = struct
  (* Use this worker as a fallback *)
  module Worker_not_found : Oban_worker = struct
    let perform job = Job_result.discard job "Worker not found"
    let backoff (job : Job.t) = 1
  end
end

(* Sample implementation example *)
module My_worker_a : Oban_worker = struct
  let perform job = Job_result.ok job
  let backoff (job : Job.t) = (Int32.to_int job.attempt) * 10
end

module My_worker_b : Oban_worker = struct
  let perform job = Job_result.error job "always fail"
  let backoff (job : Job.t) = int_of_float ((float_of_int (Int32.to_int job.attempt)) ** 3.)
end

module My_impl : Oban_impl = struct
  let to_worker (name : string) =
    match name with
    | "Elixir.MyApp.MyWorkerA" -> (module My_worker_a : Oban_worker)
    | "Elixir.MyApp.MyWorkerB" -> (module My_worker_b : Oban_worker)
    | _ -> (module Default_workers.Worker_not_found : Oban_worker)

  let queue = "default"
end

(* Runtime example *)
let () =
  let dbh = connect () in
  let jobs = Query.fetch_jobs dbh My_impl.queue 1L in
  let results = List.map (perform_job (module My_impl)) jobs in
  let _ = List.map (ack_result dbh (module My_impl)) results in
  PGOCaml.close(dbh)
