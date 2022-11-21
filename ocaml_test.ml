open Lwt
open Cohttp_lwt_unix

module ConNum = Map.Make(String)

let mapConNum = ConNum.empty

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
                    |> fliter_member "number"
                    |> filter_number) in

    let issue_list = fst issue_tup in
    let num_list = snd issue_tup in

    let _ = List.iter2 (fun content num -> ConNum.add content num mapConNum) issue_list num_list in 

    if List.length issue_list == 0 then []
    else issue_list @ (get_issues (page_num+1) res)

let sim_header = Cohttp.Header.of_list [("X-RapidAPI-Key", Sys.argv.(4)); ("X-RapidAPI-Host", "twinword-text-similarity-v1.p.rapidapi.com"); ("content-type", "application/x-www-form-urlencoded")]

let () = List.iter (fun issue_contents -> 
    let text1 = Yojson.Basic.to_string (`String Sys.argv.(2)) in
    let text2 = Yojson.Basic.to_string (`String issue_contents) in
    if not (String.equal text1 text2) then
        let () = Printf.printf "Compare %s with %s\n" text1 text2 in
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
) (get_issues 0 [])