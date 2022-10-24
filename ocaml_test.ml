(* let issue_num = Sys.argv.(1) in
    let issue_contents = Sys.argv.(2) in
        let _ = (Printf.printf "%s and %s\n" issue_num issue_contents) in
            Printf.printf "::set-output name=string::%s\n" issue_contents *)
open Lwt
open Cohttp
open Cohttp_lwt_unix

(* open Yojson *)

let body =
    Client.get ~headers:(Cohttp.Header.init_with "accept" "application/vnd.github+json") (Uri.of_string ("https://api.github.com/repos/prosyslab/dude-test/issues?state=all")) >>= fun (resp, body) ->
        let code = resp |> Response.status |> Code.code_of_status in
            Printf.printf "Response code: %d\n" code;
            Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
        Cohttp_lwt.Body.to_string body

let () = 
    let body = Lwt_main.run body in
        let json_body = Yojson.Basic.from_string body in
            let open Yojson.Basic.Util in
                let extract_issues (json: Yojson.Basic.t) : string list =
                    [json]
                        (* |> to_list *)
                        |> flatten
                        |> filter_member "body"
                        |> filter_string in
                    let body_list = extract_issues json_body in
                        List.iter (print_endline) body_list