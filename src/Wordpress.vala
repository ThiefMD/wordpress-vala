namespace Wordpress {
    public const string API_ENDPOINT = "wp/v2/";
    public const string JWT_PATH = "jwt-auth/v1/";
    public const string POST = "posts";
    public const string IMAGE = "images";

    public class Client {
        public string endpoint;
        string username;
        private string? authenticated_user;
        private Soup.Session session;
        private string blog_id;

        public Client (string url, string user, string token, string id = "1") {
            if (url.has_suffix ("/")) {
                endpoint = url + "xmlrpc.php";
            } else if (url.has_suffix (".php")) {
                endpoint = url;
            } else {
                endpoint = url + "/xmlrpc.php";
            }

            if (!endpoint.has_prefix ("http")) {
                endpoint = "https://" + endpoint;
            }

            username = user;
            authenticated_user = token;
            session = new Soup.Session ();
            blog_id = id;
        }

        public bool authenticate () {
            VariantBuilder args = new VariantBuilder(VariantType.TUPLE);
            args.add ("s", blog_id);
            args.add ("s", username);
            args.add ("s", authenticated_user);
            bool result = false;

            try {
                var message = Soup.XMLRPC.message_new (endpoint, "wp.getProfile", args.end ());
                session.send_message (message);

                debug ("Status Code: %u", message.status_code);

                if (message.status_code == 200) {
                    result = true;
                }
            } catch (Error e) {
                warning ("Could not send request to endpoint: %s", e.message);
            }

            return result;
        }

        public bool upload_image_simple (
            out string file_url,
            string local_file_path
        )
        {
            bool success = false;
            file_url = "";
            File upload_file = File.new_for_path (local_file_path);
            string file_mimetype = "application/octet-stream";

            if (!upload_file.query_exists ()) {
                warning ("Invalid file provided");
                return false;
            }

            uint8[] file_data;
            string base64_file;
            Bytes bytes;
            try {
                GLib.FileUtils.get_data(local_file_path, out file_data);
                base64_file = Base64.encode (file_data);
                bytes = new Bytes (file_data);
            } catch (GLib.FileError e) {
                warning(e.message);
                return false;
            }

            bool uncertain = false;
            string? st = ContentType.guess (upload_file.get_basename (), file_data, out uncertain);
            if (!uncertain || st != null) {
                file_mimetype = ContentType.get_mime_type (st);
            }

            VariantBuilder args2 = new VariantBuilder(VariantType.ARRAY);
            args2.add ("{sv}", "name", new Variant("s", upload_file.get_basename ()));
            args2.add ("{sv}", "type", new Variant("s", file_mimetype));
            args2.add ("{sv}", "bits", new Variant.from_bytes (VariantType.BYTESTRING, bytes, true)); //new Variant.bytestring((string)file_data));

            VariantBuilder args = new VariantBuilder(new VariantType("(sssa{sv})"));
            args.add ("s", blog_id);
            args.add ("s", username);
            args.add ("s", authenticated_user);
            args.add_value (args2.end ());

            //  print ("%s\n", base64_file.substring (0, 20));
            //  print ("%s\n", Soup.XMLRPC.build_request ("wp.uploadFile", args.end ()).substring (0, 512));

            debug ("Will upload %s : %s", file_mimetype, local_file_path);

            try {
                var message = Soup.XMLRPC.message_new (endpoint, "wp.uploadFile", args.end ());
                session.send_message (message);

                debug ("Status Code: %u", message.status_code);

                if (message.status_code == 200) {
                    Variant resp = Soup.XMLRPC.parse_response ((string) message.response_body.flatten ().data, -1, null);
                    var possible_url = resp.lookup_value ("url", VariantType.STRING);
                    if (possible_url != null) {
                        file_url = possible_url.get_string ();

                        success = true;
                    }
                }
            } catch (Error e) {
                warning ("Could not send request to endpoint: %s", e.message);
            }

            return success;
        }
    }
}