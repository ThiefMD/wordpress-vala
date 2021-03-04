# wordpress-vala

Unofficial [Wordpress](https://wordpress.org/) API client library for Vala. Still a work in progress. It currently uses XML-RPC.

This is a simple API for publishing from [ThiefMD](https://thiefmd.com), and will hopefully become fully compatible with time.

## Compilation

I recommend including `wordpress-vala` as a git submodule and adding `wordpress-vala/src/Wordpress.vala` to your sources list. This will avoid packaging conflicts and remote build system issues until I learn a better way to suggest this.

### Requirements

```
meson
ninja-build
valac
libgtk-3-dev
```

### Building

```bash
meson build
cd build
meson configure -Denable_examples=true
ninja
./examples/hello-wordpress
```

Examples require update to username and password, don't check this in

```
string user = "username";
string password = "password";
```

## ToDo:

Authentication with JWT extension.

# Quick Start

## Authentication

```vala
Wordpress.Client client = Client (url, username, password);
if (client.authenticate ()) {
    print ("You logged in!");
}
```

## Simple Post

```vala
Wordpress.Client client = Client (url, username, password);

string id;
if (client.create_post_simple (out id,
    "Hello world",
    "<p>Hello wordpress</p>"))
{
    print ("New post at %s/?p=%s", url, slug);
}
```

## Simple Image Upload

```vala
Wordpress.Client client = Client (url, username, password);

string id;
string slug;
if (client.upload_image_simple (
    out file_url,
    "/home/user/Pictures/photo.jpeg"))
{
    print ("New image at %s", file_url);
}
```