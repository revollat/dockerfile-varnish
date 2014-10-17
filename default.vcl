vcl 4.0;

import std;
import directors;

backend server1 {
    .host = "127.0.0.1";
    .port = "80";
}

acl purge {
    "localhost";
    "127.0.0.1";
    "::1";
}

sub vcl_recv {

    set req.backend_hint = vdir.backend();

    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) { # set or append the client.ip to X-Forwarded-For header
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

    if (req.method == "PURGE") {
        return (purge);
    }

    if (req.method != "GET" &&
            req.method != "HEAD" &&
            req.method != "PUT" &&
            req.method != "POST" &&
            req.method != "TRACE" &&
            req.method != "OPTIONS" &&
            req.method != "PATCH" &&
            req.method != "DELETE") {
        return (pipe);
    }

    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    set req.http.Surrogate-Capability = "key=ESI/1.0";

    if (req.http.Authorization) {
        return (pass);
    }

    return (hash);
}

sub vcl_hit {

    if (obj.ttl >= 0s) {
        return (deliver);
    }
}

sub vcl_backend_response {

    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        unset beresp.http.Surrogate-Control;
        set beresp.do_esi = true;
    }

    if (beresp.status == 301 || beresp.status == 302) {
        set beresp.http.Location = regsub(beresp.http.Location, ":[0-9]+", "");
    }

    if (beresp.ttl <= 0s || beresp.http.Set-Cookie || beresp.http.Vary == "*") {
        set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    set beresp.grace = 6h;

    return (deliver);
}
