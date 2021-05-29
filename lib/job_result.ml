type t = Ok of Job.t | Error of (Job.t * string)

let ok job = Ok job

let error job message = Error (job, message)
