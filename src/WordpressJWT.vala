namespace Wordpress {
    public const string API_ENDPOINT = "wp-json/";
    public const string REST_ROUTE = "index.php?rest_route=/";
    public const string JWT_PATH = "jwt-auth/v1/";
    public const string POST = "posts";
    public const string IMAGE = "images";

    public class Client {
        public string endpoint;
        string username;
        private string? authenticated_user;
        private Soup.Session session;
        public SList<Soup.Cookie> cookies;
        public string rest_endpoint;

        public Client (string url, string user, string token) {
            if (url.has_suffix ("/")) {
                endpoint = url;
            } else {
                endpoint = url + "/";
            }

            if (!endpoint.has_prefix ("http")) {
                endpoint = "https://" + endpoint;
            }

            username = user;
            authenticated_user = token;
            session = new Soup.Session ();
            session.user_agent = "ThiefMDPress/1.0";
            rest_endpoint = API_ENDPOINT;
        }

        public bool authenticate () {
            bool result = false;

            Soup.Session session = new Soup.Session ();
            Soup.Message msg = new Soup.Message ("POST", endpoint + rest_endpoint + JWT_PATH + "token");
            string login = "username=" + username + "&password=" + authenticated_user;
            msg.set_request ("application/x-www-form-urlencoded", Soup.MemoryUse.STATIC, login.data);

            print ("Trying: %s %s\n", msg.method, endpoint + rest_endpoint + JWT_PATH + "token");
            session.send_message (msg);
            cookies = new SList<Soup.Cookie> ();

            print ("Response: %u\n", msg.status_code);

            if (msg.status_code == 404 && rest_endpoint == API_ENDPOINT) {
                rest_endpoint = REST_ROUTE;
                result = authenticate ();
            } else {
                if (msg.status_code >= 200 && msg.status_code < 300) {

                    GLib.SList<Soup.Cookie> rec_cookies = Soup.cookies_from_response (msg);
                    debug ("Got success from server");
                    foreach (var cookie in rec_cookies) {
                        print ("Cookie %s = %s", cookie.name, cookie.value);
                        //  if (cookie.name == COOKIE) {
                        //      cookies.append (cookie);
                        //  }
                    }
                    debug ("Found : %u expected cookies", cookies.length ());
                }
            }

            return result;
        }
    }
}