open PGOCaml;;

type t = {
  id: int64;
  state: Job_state.t;
  queue: string;
  worker: string;
  args: Yojson.Safe.t;
  errors: Yojson.Safe.t option list; 
  attempt: int32;
  max_attempts: int32;
  priority: int32;
}

let t_of_obj obj =
  let errors =
    List.map (fun (err : string option) -> Option.map (Yojson.Safe.from_string) err) obj#errors
  in
  {
    id = obj#id;
    state = obj#state;
    queue = obj#queue;
    worker = obj#worker;
    args = Yojson.Safe.from_string obj#args;
    errors = errors;
    attempt = obj#attempt;
    max_attempts = obj#max_attempts;
    priority = obj#priority;
  }

let string_of_t (job : t) = string_of_int64 job.id
