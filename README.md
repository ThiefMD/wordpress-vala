# wordpress-vala

Unofficial [WordPress](https://wordpress.org/) API client library for Vala. Still a work in progress. It supports XML-RPC and REST.

This is a simple API for publishing from [ThiefMD](https://thiefmd.com), and will hopefully become fully compatible with time.

## Compilation

I recommend including `wordpress-vala` as a git submodule and adding the specific client file you want to your sources list. This will avoid packaging conflicts and remote build system issues until I learn a better way to suggest this.

XML-RPC (libsoup2): `wordpress-vala/src/Wordpress.vala`

XML-RPC (libsoup3): `wordpress-vala/src/Wordpress3.vala`

REST (libsoup2): `wordpress-vala/src/WordpressRest.vala`

REST (libsoup3): `wordpress-vala/src/WordpressRest3.vala`

REST clients require an application password.

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
./examples/hello-wordpress-rest
```

Examples require update to username and password, don't check this in

```
string user = "username";
string password = "password";
```

## ToDo:

Authentication with JWT extension.

# Quick Start

## XML-RPC Authentication

```vala
Wordpress.Client client = Client (url, username, password);
if (client.authenticate ()) {
    print ("You logged in!");
}
```

## XML-RPC Simple Post

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

## XML-RPC Simple Image Upload

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

## REST Authentication

```vala
Wordpress.Client client = Client (url, username, app_password);
if (client.authenticate ()) {
    print ("You logged in!");
}
```

## REST Simple Post

```vala
Wordpress.Client client = Client (url, username, app_password);

string id;
if (client.create_post_simple (out id,
    "Hello world",
    "<p>Hello wordpress</p>"))
{
    print ("New post at %s/?p=%s", url, id);
}
```

## REST Simple Image Upload

```vala
Wordpress.Client client = Client (url, username, app_password);

string file_url;
int media_id;
if (client.upload_image (
    out file_url,
    out media_id,
    "/home/user/Pictures/photo.jpeg"))
{
    print ("New image at %s (id=%d)", file_url, media_id);
}
```