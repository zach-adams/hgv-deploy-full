# This is my VCL file for Varnish 4.0.2 & Wordpress 4.0
#
# ASSUME The builtin VCL is called afterwards.
#

# Specify VCL new 4.0 format.
vcl 4.0;

# Imports
import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    ##.port = "8080";
    .port = "8888";
}


acl aclPurge {
    # For now, I'll only allow purges coming from localhost
    "127.0.0.1";
    "localhost";
}
acl aclBanned {
    # Private Networks 192.168.*.* [subnet mask /16 = netmask 255.255.0.0 = 16 meaningful bits left to right]
    "192.168.0.0"/16;
    # some specific malicious ip addresses
    "81.82.83.84";
    "31.5.89.4";
}

sub vcl_recv {
    ### DOC
    # https://www.varnish-cache.org/docs/4.0/users-guide/vcl-built-in-subs.html#vcl-recv
    # http://www.mediawiki.org/wiki/Manual:Varnish_caching#Configuring_Varnish_4.x
    # - The builtin VCL is always called afterwards.
    # - Happens before we check if we have this in cache already.
    # - Typically you clean up the request here, adjusting headers, managing cookies, rewriting the request, etc.

    ### vmod std:
    #   - std.log(str): Logs a string to the shared memory log, using VSL tag VCL_Log
    #   - varnishlog -i VCL_Log

    ###
    ### Allow purging
    ###
    #     Tip: it only purges the current cache entry (to purge the whole cache: do service restart instead)
    if (req.method == "PURGE") {
        if (!client.ip ~ aclPurge) {
            return (synth(405, "This IP is not allowed to send PURGE requests."));
        }
        return (purge);
    }

    ###
    ### Banning Logic (replacing the Wordpress Plugin WP-Ban)
    ###

    # IP Addresses 192.168.*.
    if (client.ip ~ aclBanned) {
        return (synth(403, "Forbidden"));
    }

    ###
    ### Do not Cache: special cases
    ###

    ### Do not Authorized requests.
    if (req.http.Authorization) {
        return(pass); // DO NOT CACHE
    }

    ### Pass any requests with the "If-None-Match" header directly.
    if (req.http.If-None-Match) {
        return(pass); // DO NOT CACHE
    }

    ### Do not cache AJAX requests.
    if (req.http.X-Requested-With == "XMLHttpRequest") {
        return(pass); // DO NOT CACHE
    }

    ### Only cache GET or HEAD requests. This makes sure the POST (and OPTIONS) requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass); // DO NOT CACHE
    }


    ### 
    ### Request URL
    ###

    # Apache: disable caching for the Apache2 server status page
    if (req.url ~ "^/server-status") {
        # do not use the cache
        return(pass); // DO NOT CACHE
    }

    ### Static files: Do not cache PDF, XML, ... files (=static & huge and no use caching them - in all Vary: variations!)
    if (req.url ~ "\.(doc|mp3|pdf|tif|tiff|xml)(\?.*|)$") {
        return(pass); // DO NOT CACHE
    }

    # Wordpress: disable caching for some parts of the backend (mostly admin stuff)
    # and WP search results.
    if (
        req.url ~ "^/wp-(login|admin)" || req.url ~ "/wp-cron.php" || req.url ~ "/wp-content/uploads/"
     || req.url ~ "preview=true"       || req.url ~ "xmlrpc.php"   || req.url ~ "\?s="
    ) {
        # do not use the cache
        return(pass); // DO NOT CACHE
    }

    # Development: my /tryme/ folder with test scripts
    if (req.url ~ "^/tryme/") {
        # do not use the cache
        return(pass); // DO NOT CACHE
    }

    # WooCommerce
    if (req.url ~ "\?add-to-cart=") {
        # do not use the cache
        return(pass); // DO NOT CACHE
    }

    # Kick DFind requests
    if (req.url ~ "^/w00tw00t") {
        return (synth(404, "Not Found"));
    }


    ### 
    ### http header Cookie
    ###     Remove some cookies (if found).
    ###
    # https://www.varnish-cache.org/docs/4.0/users-guide/increasing-your-hitrate.html#cookies

    # Unset the header for static files
    if (req.url ~ "\.(css|flv|gif|htm|html|ico|jpeg|jpg|js|mp3|mp4|pdf|png|swf|tif|tiff|xml)(\?.*|)$") {
        unset req.http.Cookie;
    }

    if (req.http.cookie) {
        # Google Analytics
        set req.http.Cookie = regsuball( req.http.Cookie, "(^|;\s*)(__utm[a-z]+)=([^;]*)", "");
        set req.http.Cookie = regsuball( req.http.Cookie, "(^|;\s*)(_ga)=([^;]*)", "");

        # Quant Capital
        set req.http.Cookie = regsuball( req.http.Cookie, "(^|;\s*)(__qc[a-z]+)=([^;]*)", "");

        # __gad __gads
        set req.http.Cookie = regsuball( req.http.Cookie, "(^|;\s*)(__gad[a-z]+)=([^;]*)", "");

        # Google Cookie consent (client javascript cookie)
        set req.http.Cookie = regsuball( req.http.Cookie, "(^|;\s*)(displayCookieConsent)=([^;]*)", "");

        # Other known Cookies: remove them (if found).
        set req.http.Cookie = regsuball( req.http.Cookie, "(^|;\s*)(__CT_Data)=([^;]*)", "");
        set req.http.Cookie = regsuball( req.http.Cookie, "(^|;\s*)(WRIgnore|WRUID)=([^;]*)", "");


        # PostAction: Remove (once and if found) a ";" prefix followed by 0..n whitespaces.
        # INFO \s* = 0..n whitespace characters
        set req.http.Cookie = regsub( req.http.Cookie, "^;\s*", "" );

        # PostAction: Unset the header if it is empty or 0..n whitespaces.
        if ( req.http.cookie ~ "^\s*$" ) {
            unset req.http.Cookie;
        }
    }


    ###
    ### Normalize the Accept-Language header
    ### We do not need a cache for each language-country combination! Just keep en-* and nl-* for future use.
    ### https://www.varnish-cache.org/docs/4.0/users-guide/increasing-your-hitrate.html#http-vary
    if (req.http.Accept-Language) {
        if (req.http.Accept-Language ~ "^en") {
            set req.http.Accept-Language = "en";
        } elsif (req.http.Accept-Language ~ "^nl") {
            set req.http.Accept-Language = "nl";
        } else {
            # Unknown language. Set it to English.
            set req.http.Accept-Language = "en";
        }
    }


    ###
    ### Varnish v4: vcl_recv must now return hash instead of lookup
    return(hash);
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    # main variable = beresp.
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client. You can do accounting or modifying the final object here.

    # main variable = resp.

    set resp.http.Server = "mine";
    set resp.http.X-Powered-By = "electricity";
}

sub vcl_pipe {
    # https://www.varnish-software.com/blog/using-pipe-varnish
    # Note that only the first request to the backend will have X-Forwarded-For set.
    # If you use X-Forwarded-For and want to have it set for all requests, 
    # then make sure to use this: set req.http.connection = "close";
    # (This code is not necessary if you do not do any request rewriting.)

    set req.http.connection = "close";
}
###EndOf: .vcl
