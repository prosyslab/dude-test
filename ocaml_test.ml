open Lwt
open Cohttp
open Cohttp_lwt_unix

module ConNum = Map.Make(String)

let map_ConNum = ref ConNum.empty

let rec get_issues page_num res =
    let body =
        Client.get ~headers: (Cohttp.Header.init_with "accept" "application/vnd.github+json") (Uri.of_string ("https://api.github.com/repos/" ^ Sys.argv.(3) ^ "/issues?state=all&per_page=100&" ^ "page=" ^ (Int.to_string page_num))) >>= fun (_, body) ->
            Cohttp_lwt.Body.to_string body in
    
    let issue_tup =
        let body = Lwt_main.run body in
            let open Yojson.Basic.Util in
                ([body |> Yojson.Basic.from_string]
                    |> flatten
                    |> filter_member "body"
                    |> filter_string,
                 [body |> Yojson.Basic.from_string]
                    |> flatten
                    |> filter_member "number"
                    |> filter_int) 
    in

    let issue_list = fst issue_tup in
    let num_list = snd issue_tup in

    let _ = List.iter2 (fun content num ->
        if num != Sys.argv.(1) then
            map_ConNum := ConNum.add content num !map_ConNum) issue_list num_list in 

    if List.length issue_list == 0 then []
    else issue_list @ (get_issues (page_num+1) res)

let sim_header = Cohttp.Header.of_list [("X-RapidAPI-Key", Sys.argv.(4)); ("X-RapidAPI-Host", "twinword-text-similarity-v1.p.rapidapi.com"); ("content-type", "application/x-www-form-urlencoded")]

let threshold_sim = 0.20
let max_sim = ref (-1.0)
let max_contents = ref ""

let () = List.iter (fun issue_contents -> 
    let text1 = Yojson.Basic.to_string (`String Sys.argv.(2)) in
    let text2 = Yojson.Basic.to_string (`String issue_contents) in
    let () = Printf.printf "Compare %s with %s\n" text1 text2 in
        let body =
            Client.get  ~headers:sim_header (Uri.of_string ("https://twinword-text-similarity-v1.p.rapidapi.com/similarity/?" ^ "text1=" ^ text1 ^ "&" ^ "text2=" ^ text2)) >>= fun (_, body) ->
                Cohttp_lwt.Body.to_string body in

    let body = Lwt_main.run body in
        let json_body = Yojson.Basic.from_string body in
            let open Yojson.Basic.Util in
                let cur_sim = List.hd ([json_body] |> filter_member "similarity" |> filter_number) in
                    if cur_sim > threshold_sim && cur_sim > !max_sim then
                        let _ = max_sim := cur_sim in
                        max_contents := issue_contents
) (get_issues 0 [])

let _ =
    if !max_sim == -1.0 then Sys.command ("echo \"dup_num=" ^ (Int.to_string (-1)) ^ "\" >> $GITHUB_OUTPUT")
    else Sys.command ("echo \"dup_num=" ^ (Int.to_string (ConNum.find !max_contents !map_ConNum)) ^ "\" >> $GITHUB_OUTPUT")

let _ =
    if !max_sim == -1.0 then ()
    else 
        (* Leave a comment *)
        let post_body = Cohttp_lwt.Body.of_string (Yojson.Basic.to_string (
            `Assoc[("body", (`String ("Possible duplication detected. Refer to #" ^ (Int.to_string (ConNum.find !max_contents !map_ConNum)))))]
        )) in
        let post_header = Cohttp.Header.add_authorization (Cohttp.Header.init_with "accept" "application/vnd.github+json") (Cohttp.Auth.credential_of_string ("Bearer " ^ Sys.argv.(5))) in
        let body =
            Client.post ~body:post_body ~headers:post_header (Uri.of_string ("https://api.github.com/repos/" ^ Sys.argv.(3) ^ "/issues/" ^ Sys.argv.(1) ^ "/comments")) >>= fun (resp, body) ->
                let code = resp |> Response.status |> Code.code_of_status in
                    Printf.printf "Response code: %d\n" code;
                Cohttp_lwt.Body.to_string body in

        let _ = Lwt_main.run body in ()