public class HelloMarkdownRest {
    public static int main (string[] args) {
        string user = "username";
        string app_password = "app_password";
        string endpoint = "https://myblog.url";

        Wordpress.RestClient client = new Wordpress.RestClient (endpoint, user, app_password);
        string id;
        if (client.authenticate ()) {
            print ("Authenticated!
");
        } else {
            print ("Could not login
");
            return 0;
        }

        string markdown = """
# Hello from Vala!

This post was created using **Markdown** converted to **WordPress Blocks**.

## Features supported:
* Headers
* Bold and Italic text
* Lists
* Code blocks

```vala
void main() {
    print("Hello WordPress!");
}
```

Enjoy!
""";

        if (client.create_post_from_markdown(
            out id,
            "Hello Markdown (Blocks)",
            markdown,
            false))
        {
            print ("\n\n** New block post at %s/?p=%s\n\n", endpoint, id);
        } else {
            print ("Block post failure\n");
        }

        // Sending as "Classic Editor" style HTML (no blocks)
        // We'll just replace the block comments for a simple comparison
        string html_only = Wordpress.MarkdownConverter.to_blocks (markdown)
            .replace ("<!-- wp:paragraph -->\n", "")
            .replace ("\n<!-- /wp:paragraph -->", "")
            .replace ("<!-- wp:heading {\"level\":1} -->\n", "")
            .replace ("\n<!-- /wp:heading -->", "")
            .replace ("<!-- wp:heading {\"level\":2} -->\n", "")
            .replace ("\n<!-- /wp:heading -->", "")
            .replace ("<!-- wp:list {\"ordered\":false} -->\n", "")
            .replace ("\n<!-- /wp:list -->", "")
            .replace ("<!-- wp:code -->\n", "")
            .replace ("\n<!-- /wp:code -->", "");

        if (client.create_post_simple(
            out id,
            "Hello Markdown (Raw HTML)",
            html_only,
            false))
        {
            print ("\n\n** New simple post at %s/?p=%s\n\n", endpoint, id);
        } else {
            print ("Simple post failure\n");
        }

        return 0;
    }
}
