let string_of_oban_job_state = Job_state.string_of_t
let oban_job_state_of_string = Job_state.t_of_string

let all dbh =
  [%pgsql.object dbh "select * from oban_jobs"]

let fetch_jobs dbh queue demand =
  let job_objs =
    [%pgsql.object dbh
    "UPDATE oban_jobs
    SET state = ${Executing},
        attempted_at = NOW()
    WHERE id in
      (SELECT id
       FROM oban_jobs j
       WHERE j.state = ${Available}
       AND j.queue = ${queue}
       ORDER BY j.priority ASC, j.scheduled_at ASC, j.id ASC
       LIMIT ${demand}
       FOR UPDATE skip locked)
     RETURNING *"]
  in
  List.map (Job.t_of_obj) job_objs

let complete_job dbh job_id =
  [%pgsql dbh 
  "UPDATE oban_jobs 
  SET state = ${Completed}, completed_at = NOW()
  WHERE id = ${job_id}"]

(* TODO: backoff *)

let error_job dbh job_id error =
  [%pgsql dbh 
  "UPDATE oban_jobs
  SET state = ${Retryable}, 
      scheduled_at = NOW() + interval '20 seconds',
      errors = array_append(errors, ${error})
  WHERE id = ${job_id}"]
