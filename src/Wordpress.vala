namespace Wordpress {
    public class Client {
        public string endpoint;
        string username;
        private string? authenticated_user;
        private Soup.Session session;
        private string blog_id;
        private int author_id;
        private Gee.Map<string, int> uploaded_images;

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
            uploaded_images = new Gee.HashMap<string, int> ();
        }

        public bool authenticate () {
            VariantBuilder args = new VariantBuilder(VariantType.TUPLE);
            args.add ("s", blog_id);
            args.add ("s", username);
            args.add ("s", authenticated_user);
            bool result = false;

            try {
                var message = Soup.XMLRPC.message_new (endpoint, "wp.getProfile", args.end ());
                MainLoop loop = new MainLoop ();
                session.queue_message (message, (sess, mess) => {
                    try {
                        debug ("Status Code: %u", mess.status_code);

                        if (mess.status_code == 200) {
                            Variant resp = Soup.XMLRPC.parse_response ((string) mess.response_body.flatten ().data, -1, null);
                            var possible_id = resp.lookup_value ("user_id", VariantType.STRING);
                            if (possible_id != null) {
                                author_id = int.parse(possible_id.get_string ());

                                result = true;
                            }
                        } else {
                            warning ("Status Code: %u", mess.status_code);
                            warning ("Body: %s", (string) mess.response_body.flatten ().data);
                        }
                    } catch (Error e) {
                        warning ("Could not parse auth response: %s", e.message);
                    }
                    loop.quit ();
                });
                loop.run ();
            } catch (Error e) {
                warning ("Could not send request to endpoint: %s", e.message);
            }

            return result;
        }

        public bool create_post_simple (
            out string id,
            string title,
            string html_body,
            bool publish = true,
            string cover_image_url = "",
            string[]? tags = null,
            bool strip_new_lines = false)
        {
            bool success = false;
            id = "";

            VariantBuilder args2 = new VariantBuilder(new VariantType("a{sv}"));
            args2.add ("{sv}", "post_type", new Variant("s", "post"));
            args2.add ("{sv}", "post_status", new Variant("s", publish ? "publish" : "draft"));
            args2.add ("{sv}", "post_title", new Variant("s", title));
            args2.add ("{sv}", "post_author", new Variant("u", author_id));
            try {
                if (strip_new_lines) {
                    Regex regex = new Regex ("[\\r\\n\\R]", RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.BSR_ANYCRLF);
                    args2.add ("{sv}", "post_content", new Variant("s", regex.replace (html_body, html_body.length, 0, " ", RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF)));
                } else {
                    args2.add ("{sv}", "post_content", new Variant("s", html_body));
                }
            } catch (Error e) {
                warning ("Could not strip new line characters from post.");
                return false;
            }

            debug ("Adding image: %s", cover_image_url);
            if (uploaded_images.has_key (cover_image_url)) {
                debug ("added %d", uploaded_images.get (cover_image_url));
                args2.add ("{sv}", "post_thumbnail", new Variant("i", uploaded_images.get (cover_image_url)));
            }

            VariantBuilder args = new VariantBuilder(new VariantType("(sssa{sv})"));
            args.add ("s", blog_id);
            args.add ("s", username);
            args.add ("s", authenticated_user);
            args.add_value (args2.end ());

            try {
                var message = Soup.XMLRPC.message_new (endpoint, "wp.newPost", args.end ());
                MainLoop loop = new MainLoop ();
                string image_id = "";
                session.queue_message (message, (sess, mess) => {
                    try {
                        debug ("Status Code: %u", mess.status_code);
                        if (mess.status_code == 200) {
                            Variant resp = Soup.XMLRPC.parse_response ((string) mess.response_body.flatten ().data, -1, null);
                            size_t length = 0;
                            image_id = resp.get_string (out length);
                            if (length > 0) {
                                success = true;
                            }
                        } else if (!strip_new_lines && (mess.status_code == 418 || mess.status_code == 500)) {
                            warning ("Encountered what appears to be mod_security error, trying again with workaround");
                            success = create_post_simple (
                                out image_id,
                                title,
                                html_body,
                                publish,
                                cover_image_url,
                                tags,
                                true);
                        } else {
                            warning ("Status Code: %u", mess.status_code);
                            warning ("Body: %s", (string) mess.response_body.flatten ().data);
                        }
                    } catch (Error e) {
                        warning ("Error processing response: %s", e.message);
                    }
                    loop.quit ();
                });

                loop.run ();
                id = image_id;
            } catch (Error e) {
                warning ("Could not send request to endpoint: %s", e.message);
            }

            return success;
        }

        public bool create_post_from_markdown (
            out string id,
            string title,
            string markdown,
            bool publish = true,
            string cover_image_url = "",
            string[]? tags = null)
        {
            string html_blocks = MarkdownConverter.to_blocks (markdown);
            return create_post_simple (out id, title, html_blocks, publish, cover_image_url, tags);
        }

        public bool upload_image_simple (
            out string file_url,
            string local_file_path
        )
        {
            int id;
            return upload_image (out file_url, out id, local_file_path);
        }

        public bool upload_image (
            out string file_url,
            out int id,
            string local_file_path
        )
        {
            bool success = false;
            file_url = "";
            id = -1;
            File upload_file = File.new_for_path (local_file_path);
            string file_mimetype = "application/octet-stream";

            if (!upload_file.query_exists ()) {
                warning ("Invalid file provided");
                return false;
            }

            uint8[] file_data;
            // string base64_file;
            Bytes bytes;
            try {
                GLib.FileUtils.get_data(local_file_path, out file_data);
                // base64_file = Base64.encode (file_data);
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
            args2.add ("{sv}", "bits", new Variant.from_bytes (VariantType.BYTESTRING, bytes, true));

            VariantBuilder args = new VariantBuilder(new VariantType("(sssa{sv})"));
            args.add ("s", blog_id);
            args.add ("s", username);
            args.add ("s", authenticated_user);
            args.add_value (args2.end ());

            //  print ("%s\n", base64_file.substring (0, 20));
            //  print ("%s\n", Soup.XMLRPC.build_request ("wp.uploadFile", args.end ()).substring (0, 512));

            debug ("Will upload %s : %s", file_mimetype, local_file_path);

            try {
                string file_res = "";
                int id_res = -1;
                MainLoop loop = new MainLoop ();
                var message = Soup.XMLRPC.message_new (endpoint, "wp.uploadFile", args.end ());
                session.queue_message (message, (sess, mess) => {
                    try {
                        debug ("Status Code: %u", mess.status_code);

                        if (mess.status_code == 200) {
                            Variant resp = Soup.XMLRPC.parse_response ((string) mess.response_body.flatten ().data, -1, null);
                            var possible_url = resp.lookup_value ("url", VariantType.STRING);
                            var possible_id = resp.lookup_value ("id", VariantType.STRING);
                            if (possible_url != null) {
                                file_res = possible_url.get_string ();
                                if (int.try_parse (possible_id.get_string (), out id_res)) {
                                    success = true;
                                    uploaded_images.set (file_res, id_res);
                                }
                            }
                        } else {
                            warning ("Status Code: %u", mess.status_code);
                            warning ("Body: %s", (string) mess.response_body.flatten ().data);
                        }
                    } catch (Error e) {
                        warning ("Could not parse image upload response: %s", e.message);
                    }
                    loop.quit ();
                });
                loop.run ();
                file_url = file_res;
                id = id_res;
            } catch (Error e) {
                warning ("Could not send request to endpoint: %s", e.message);
            }

            return success;
        }
    }
}
