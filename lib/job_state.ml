type t = Available | Scheduled | Executing | Retryable | Completed | Discarded | Cancelled

let t_of_string str = 
  match str with
  | "available" -> Available
  | "scheduled" -> Scheduled
  | "executing" -> Executing
  | "retryable" -> Retryable
  | "completed" -> Completed
  | "discarded" -> Discarded
  | "cancelled" -> Cancelled
  | _ -> failwith "Invalid job state"

let string_of_t job_state =
  match job_state with
  | Available ->"available"
  | Scheduled ->"scheduled"
  | Executing ->"executing"
  | Retryable ->"retryable"
  | Completed ->"completed"
  | Discarded ->"discarded"
  | Cancelled ->"cancelled"
