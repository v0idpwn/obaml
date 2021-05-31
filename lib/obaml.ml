open PGOCaml;;

(* Exporting internal modules *)
module Job_result = Job_result

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
    let backoff _job = 1
  end
end
