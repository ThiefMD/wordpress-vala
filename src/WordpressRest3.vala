namespace Wordpress {
    public class RestClient {
        public string endpoint;
        public string displayname;
        public string blog_url;
        private string username;
        private string? authenticated_user;
        private Soup.Session session;
        private string blog_id;
        private int author_id;
        private Gee.Map<string, int> uploaded_images;

        public RestClient (string url, string user, string token, string id = "1") {
            author_id = -1;
            if (url.has_suffix ("/")) {
                endpoint = url + "wp-json/wp/v2/";
            } else if (url.has_suffix (".php")) {
                endpoint = url;
            } else {
                endpoint = url + "/wp-json/wp/v2/";
            }

            if (!endpoint.has_prefix ("http")) {
                endpoint = "https://" + endpoint;
            }

            username = user;
            blog_url = url;
            authenticated_user = "Basic " + Base64.encode ((user + ":" + token).data);
            session = new Soup.Session ();
            blog_id = id;
            uploaded_images = new Gee.HashMap<string, int> ();
        }

        public bool authenticate () {
            bool result = false;

            WebCall call = new WebCall (endpoint,  "users/me");
            call.set_get ();
            call.add_header ("Authorization", authenticated_user);
            call.perform_call ();

            if (call.response_code >= 200 && call.response_code < 300) {
                try {
                    var parser = new Json.Parser ();
                    parser.load_from_data (call.response_str);
                    var json_obj = parser.get_root ().get_object ();
                    if (json_obj.has_member ("id")) {
                        author_id = (int)json_obj.get_int_member ("id");
                    }

                    if (json_obj.has_member ("username")) {
                        displayname = json_obj.get_string_member ("username");
                    }

                    result = true;
                } catch (Error e) {
                    warning ("Error parsing response: %s", e.message);
                }
            }

            return result;
        }

        public bool create_post_simple (
            out string id,
            string title,
            string html_body,
            bool publish = true,
            int cover_image_id = -1,
            string[]? tags = null,
            bool strip_new_lines = false)
        {
            bool success = false;
            id = "";

            if (author_id < 0) {
                return success;
            }

            Post new_post = new Post();
            new_post.author = author_id;
            new_post.title.set_content (title);
            new_post.content.set_content (html_body);
            if (publish) {
                new_post.status = "publish";
            } else {
                new_post.status = "draft";
            }
            new_post.format = "standard";

            if (cover_image_id >= 0) {
                new_post.featured_media = cover_image_id;
            }

            Json.Node root = Json.gobject_serialize (new_post);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);
            if (cover_image_id >= 0) {
                request_body = request_body.replace ("\"featured-media\":%d".printf (cover_image_id), "\"featured_media\":%d".printf (cover_image_id));
            }

            WebCall make_post = new WebCall (endpoint, "posts");
            make_post.set_post ();
            make_post.set_body (request_body);
            make_post.add_header ("Authorization", authenticated_user);

            debug ("Request body: %s", request_body);

            make_post.perform_call ();

            if (make_post.err_resp == null) {
                try {
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_data (make_post.response_str);
                    Json.Node data = parser.get_root ();
                    Post response = Json.gobject_deserialize (
                        typeof (Post),
                        data)
                        as Post;

                    if (response != null) {
                        success = true;
                        id = "%d".printf (response.id);
                    }
                } catch (Error e) {
                    warning ("Unable to publish post: %s", e.message);
                }
            }

            return success;
        }

        public bool create_post_from_markdown (
            out string id,
            string title,
            string markdown,
            bool publish = true,
            int cover_image_id = -1,
            string[]? tags = null)
        {
            string html_blocks = MarkdownConverter.to_blocks (markdown);
            return create_post_simple (out id, title, html_blocks, publish, cover_image_id, tags);
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
            id = -1;
            file_url = "";

            if (author_id < 0) {
                return success;
            }

            File upload_file = File.new_for_path (local_file_path);
            string file_mimetype = "application/octet-stream";

            if (!upload_file.query_exists ()) {
                warning ("Invalid file provided");
                return false;
            }

            uint8[] file_data;
            try {
                GLib.FileUtils.get_data(local_file_path, out file_data);
            } catch (GLib.FileError e) {
                warning(e.message);
                return false;
            }

            bool uncertain = false;
            string? st = ContentType.guess (upload_file.get_basename (), file_data, out uncertain);
            if (!uncertain || st != null) {
                file_mimetype = ContentType.get_mime_type (st);
            }

            debug ("Will upload %s : %s", file_mimetype, local_file_path);

            Bytes buffer = new Bytes.take(file_data);
            Soup.Multipart multipart = new Soup.Multipart("multipart/form-data");
            multipart.append_form_file ("file", upload_file.get_path (), file_mimetype, buffer);

            WebCall call = new WebCall (endpoint, "media");
            call.set_multipart (multipart);
            call.add_header ("Authorization", authenticated_user);
            call.perform_call ();

            if (call.err_resp == null) {
                try {
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_data (call.response_str);
                    Json.Node data = parser.get_root ();
                    Media response = Json.gobject_deserialize (
                        typeof (Media),
                        data)
                        as Media;

                    if (response != null) {
                        success = true;
                        id = response.id;
                        file_url = response.guid.raw;
                    }
                } catch (Error e) {
                    warning ("Unable to publish post: %s", e.message);
                }
            }

            return success;
        }
    }

    public class ErrorRespose : GLib.Object, Json.Serializable {
        public string code { get; set; }
        public string message { get; set; }
    }

    public class Content : GLib.Object, Json.Serializable {
        public string rendered { get; set; }
        public string raw { get; set; }
        public bool IsProtected { get; set; }
        public void set_content (string str) {
            rendered = str;
            raw = str;
        }
    }

    public class Media : GLib.Object, Json.Serializable {
        public int id { get; set; }
        public DateTime date { get; set; }
        public DateTime date_gmt { get; set; }
        public Content guid { get; set; }
        public DateTime modified { get; set; }
        public DateTime modified_gmt { get; set; }
        public string slug { get; set; }
        public string status { get; set; }
        public Content title { get; set; }
        public int author { get; set; }

        public Media () {
            title = new Content ();
        }
    }

    public class Post : Content {
        public int id { get; set; }
        public DateTime date { get; set; }
        public DateTime date_gmt { get; set; }
        public Content guid { get; set; }
        public DateTime modified { get; set; }
        public DateTime modified_gmt { get; set; }
        public string password { get; set; }
        public string slug { get; set; }
        public string status { get; set; }
        public string link { get; set; }
        public int featured_media { get; set; }
        public string format { get; set; }
        public Content title { get; set; }
        public Content excerpt { get; set; }
        public Content content { get; set; }
        public int author { get; set; }

        public string generated_slug { get; set; }
        public string permalink_template { get; set; }

        public Post () {
            title = new Content ();
            excerpt = new Content ();
            content = new Content ();
        }
    }

    private class WebCall {
        private Soup.Session session;
        private Soup.Message message;
        private string url;
        private string body;
        private bool is_mime = false;

        public string response_str;
        public uint response_code;

        public ErrorRespose? err_resp;

        public WebCall (string endpoint, string api) {
            url = endpoint + api;
            session = new Soup.Session ();
            body = "";
            err_resp = null;
        }

        public void set_body (string data) {
            body = data;
        }

        public void set_multipart (Soup.Multipart multipart) {
            message = new Soup.Message.from_multipart (url, multipart);
            is_mime = true;
        }

        public void set_get () {
            message = new Soup.Message ("GET", url);
        }

        public void set_put () {
            message = new Soup.Message ("PUT", url);
        }

        public void set_delete () {
            message = new Soup.Message ("DELETE", url);
        }

        public void set_post () {
            message = new Soup.Message ("POST", url);
        }

        public void add_header (string key, string value) {
            message.request_headers.append (key, value);
        }

        public void add_cookies (SList<Soup.Cookie> cookies) {
            Soup.cookies_to_request (cookies, message);
        }

        public bool perform_call () {
            bool success = false;

            if (message == null) {
                return false;
            }

            if (body != "") {
                Bytes body_bytes = new Bytes.static (body.data);
                message.set_request_body_from_bytes ("application/json", body_bytes);
            } else {
                if (!is_mime) {
                    add_header ("Content-Type", "application/json");
                } else {
                    add_header ("Content-Type", Soup.FORM_MIME_TYPE_MULTIPART);
                }
            }

            MainLoop loop = new MainLoop ();

            session.send_and_read_async.begin (message, 0, null, (obj, res) => {
                try {
                    var response = session.send_and_read_async.end (res);
                    response_str = response != null ? (string)response.get_data () : "";
                    response_code = message.status_code;

                    if (response_str != null && response_str != "") {
                        debug ("Non-empty body");
                    }

                    if (response_code >= 200 && response_code <= 250) {
                        success = true;
                        debug ("Success HTTP code");
                    } else {
                        try {
                            Json.Parser parser = new Json.Parser ();
                            parser.load_from_data (response_str);
                            Json.Node data = parser.get_root ();
                            err_resp = Json.gobject_deserialize (
                                typeof (ErrorRespose),
                                data)
                                as ErrorRespose;
                        } catch (Error e) {
                            warning ("Unable to perform call: %s", e.message);
                        }
                    }
                } catch (Error e) {
                    warning ("Error sending request: %s", e.message);
                }
                loop.quit ();
            });

            loop.run ();
            return success;
        }
    }
}
