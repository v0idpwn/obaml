type t = 
  | Ok of Job.t 
  | Error of (Job.t * string)
  | Discard of (Job.t * string)
  | Snooze of (Job.t * int)

let ok job = Ok job

let error job message = Error (job, message)

let discard job message = Discard (job, message)

let snooze job time = Snooze (job, time)
