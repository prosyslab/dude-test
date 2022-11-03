(* let issue_num = Sys.argv.(1) in
    let issue_contents = Sys.argv.(2) in
        let _ = (Printf.printf "%s and %s\n" issue_num issue_contents) in
            Printf.printf "::set-output name=string::%s\n" issue_contents *)
open Lwt
open Cohttp
open Cohttp_lwt_unix

(* open Yojson *)

let body =
    Client.get ~headers:(Cohttp.Header.init_with "accept" "application/vnd.github+json") (Uri.of_string ("https://api.github.com/repos/" ^ Sys.argv.(3) ^ "/issues?state=all")) >>= fun (resp, body) ->
        let code = resp |> Response.status |> Code.code_of_status in
            Printf.printf "Response code: %d\n" code;
            Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
        Cohttp_lwt.Body.to_string body

let issue_list = 
    let body = Lwt_main.run body in
        let json_body = Yojson.Basic.from_string body in
            let open Yojson.Basic.Util in
                let extract_issues (json: Yojson.Basic.t) : string list =
                    [json]
                        (* |> to_list *)
                        |> flatten
                        |> filter_member "body"
                        |> filter_string in
                    (* let body_list = extract_issues json_body in
                        List.iter (print_endline) body_list *)
                        extract_issues json_body

let sim_header = Cohttp.Header.of_list [("X-RapidAPI-Key", Sys.argv.(4)); ("X-RapidAPI-Host", "twinword-text-similarity-v1.p.rapidapi.com"); ("content-type", "application/x-www-form-urlencoded")]

let () = List.iter (fun issue_contents -> 
    let text1 = Yojson.Basic.to_string (`String Sys.argv.(2)) in
    let text2 = Yojson.Basic.to_string (`String issue_contents) in
    let () = Printf.printf "Compare %s with %s\n" text1 text2 in
        if !String.equal text1 text2 then
            let body =
                Client.get  ~headers:sim_header (Uri.of_string ("https://twinword-text-similarity-v1.p.rapidapi.com/similarity/?" ^ "text1=" ^ text1 ^ "&" ^ "text2=" ^ text2)) >>= fun (_, body) ->
                    (* let code = resp |> Response.status |> Code.code_of_status in *)
                        (* Printf.printf "Response code: %d\n" code; *)
                        (* Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string); *)
                    Cohttp_lwt.Body.to_string body in

    let body = Lwt_main.run body in
        let json_body = Yojson.Basic.from_string body in
            let open Yojson.Basic.Util in
                Printf.printf "- Similarity: %s\n" (Float.to_string (List.hd ([json_body] |> filter_member "similarity" |> filter_number)))
) issue_list