open Cmdliner
open Common

let ca_extensions =
  [ (true, (`Basic_constraints (true, None)))
  ; (true, (`Key_usage [ `Key_cert_sign
                       ; `CRL_sign
                       ; `Digital_signature
                       ; `Content_commitment
                       ]))
  ]

let selfsign common_name length days is_ca certfile keyfile =
  let (issuer : X509.component list) =
    [ `CN common_name ]
  in
  let start,expire = make_dates days in
  Nocrypto_entropy_unix.initialize ();
  let privkey = `RSA (Nocrypto.Rsa.generate length) in
  let ext = if is_ca then ca_extensions else [] in
  let csr = X509.CA.request issuer privkey in
  let cert = X509.CA.sign ~valid_from:start ~valid_until:expire ~extensions:ext
      csr privkey issuer in
  let cert_pem = X509.Encoding.Pem.Certificate.to_pem_cstruct1 cert in
  let key_pem = X509.Encoding.Pem.Private_key.to_pem_cstruct1 privkey in
  match (write_pem certfile cert_pem, write_pem keyfile key_pem) with
  | Ok, Ok -> `Ok
  | Error str, _ | _, Error str -> Printf.eprintf "%s\n" str; `Error

let selfsign_t = Term.(pure selfsign $ common_name $ length $ days $ is_ca
                       $ certfile $ keyfile )

let info =
  let doc = "generate a self-signed certificate" in
  let man = [ `S "BUGS";
              `P "Submit bugs at https://github.com/yomimono/ocaml-certify";] in
  Term.info "selfsign" ~doc ~man

let () =
  match Term.eval (selfsign_t, info) with
  | `Help -> exit 0 (* TODO: not clear to me how we generate this case *)
  | `Version -> exit 0  (* TODO: not clear to me how we generate this case *)
  | `Error _ -> exit 1
  | `Ok _ -> exit 0
