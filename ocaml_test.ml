(* let issue_num = Sys.argv.(1) in
    let issue_contents = Sys.argv.(2) in
        let _ = (Printf.printf "%s and %s\n" issue_num issue_contents) in
            Printf.printf "::set-output name=string::%s\n" issue_contents *)
open Lwt
open Cohttp
open Cohttp_lwt_unix

let body =
    Client.get (Cohttp.Header.init_with "accept" "application/vnd.github+json") Sys.argv.(3)^"/issues?state=all" >>= fun (resp, body) -> (* is it okay?? *)
        let code = resp |> Response.status |> Code.code_of_status in
            Printf.printf "Response code: %d\n" code;
            Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
            body |> Cohttp_lwt.Body.to_string >|= fun body ->
                Printf.printf "Body of length: %d\n" (String.length body);
            body

let () =
    let body = Lwt_main.run body in
        print_endline ("Received body\n" ^ body)