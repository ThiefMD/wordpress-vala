public class HelloWordpressRest {
    public static int main (string[] args) {
        string user = "username";
        string app_password = "app_password";
        string endpoint = "https://myblog.url";

        Wordpress.Client client = new Wordpress.Client (endpoint, user, app_password);
        string id;
        if (client.authenticate ()) {
            print ("Authenticated!\n");
        } else {
            print ("Could not login\n");
            return 0;
        }

        string file_url;
        int media_id;
        if (client.upload_image (
            out file_url,
            out media_id,
            "/home/kmwallio/Pictures/bread.jpeg"
            ))
        {
            print ("Uploaded Image: %s (id=%d)\n", file_url, media_id);
        } else {
            print ("Image failure\n");
            return 0;
        }

        if (client.create_post_simple(
            out id,
            "Hello world",
            "<p>Hello Wordpress</p>\n<img src='%s' />".printf (file_url),
            false,
            media_id,
            {"Sample", "Post"}))
        {
            print ("\n\n** New post at %s/?p=%s\n\n", endpoint, id);
        } else {
            print ("Post failure\n");
        }

        return 0;
    }
}
