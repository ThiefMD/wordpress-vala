public class HelloWordpress {
    public static int main (string[] args) {
        string user = "username";
        string password = "password";
        string endpoint = "https://myblog.url";

        Wordpress.XmlRpcClient client = new Wordpress.XmlRpcClient (endpoint, user, password);
        string id;
        string slug;
        if (client.authenticate ()) {
            print ("Authenticated!\n");
        } else {
            print ("Could not login\n");
            return 0;
        }

        string file_url;
        if (client.upload_image_simple (
            out file_url,
            "/home/kmwallio/Pictures/bread.jpeg"
            ))
        {
            print ("Uploaded Image: %s\n", file_url);
        } else {
            print ("Image failure\n");
            return 0;
        }

        if (client.create_post_simple(
            out id,
            "Hello world",
            "<p>Hello Wordpress</p>\n<img src='%s' />".printf (file_url),
            false,
            file_url,
            {"Sample", "Post"}))
        {
            print ("\n\n** New post at %s/?p=%s\n\n", endpoint, id);
        } else {
            print ("Post failure\n");
        }

        return 0;
    }
}