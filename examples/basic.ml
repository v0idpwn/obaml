(* Example usage of the obaml library 
   Fetches a single job, performs it and then acks the result
 *)

open PGOCaml;;
open Obaml;;

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

let () =
  let dbh = connect () in
  let jobs = Query.fetch_jobs dbh My_impl.queue 1L in
  let results = List.map (perform_job (module My_impl)) jobs in
  let _ = List.map (ack_result dbh (module My_impl)) results in
  PGOCaml.close(dbh)
