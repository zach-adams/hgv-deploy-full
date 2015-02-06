backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

acl purge {
        "127.0.0.1";
}

sub vcl_recv {
	# Allow purge requests
	if (req.request == "PURGE") {
		if (!client.ip ~ purge) {
			error 405 "Not allowed.";
		}
		ban("req.url ~ ^" + req.url + " && req.http.host == " + req.http.host);
		return(lookup);
	}

	# Add header for sending client ip to backend
	set     req.http.X-Forwarded-For = client.ip;

	# Normalize     content-encoding
	if (req.http.Accept-Encoding) {
		if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|lzma|tbz)(\?.*|)$") {
			remove req.http.Accept-Encoding;
		} elsif (req.http.Accept-Encoding ~ "gzip") {
			set req.http.Accept-Encoding = "gzip";
		} elsif (req.http.Accept-Encoding ~ "deflate") {
			set req.http.Accept-Encoding = "deflate";
		} else {
			remove req.http.Accept-Encoding;
		}
	}

    # Remove cookies and query string for real static files
    if (req.url ~ "^/[^?]+\.(gif|jpg|jpeg|swf|css|js|txt|flv|mp3|mp4|pdf|ico|png|gz|zip|lzma|bz2|tgz|tbz)(\?.*|)$") {
       unset req.http.cookie;
       set req.url = regsub(req.url, "\?.*$", "");
    }

	# dont cache woocommerce pages or yith wishlist
	if (req.url ~ "^/(cart|my-account|checkout|addons|wishlist)") {
		return (pass);
	}
	if (req.url ~ "^/(cart|my-account|checkout|addons|wishlist)/") {
		return (pass);
	}
	if (req.url ~ "(cart|my-account|checkout|addons|wishlist)") {
		return (pass);
	}
	if (req.url ~ "(cart|my-account|checkout|addons|wishlist)/") {
		return (pass);
	}
	if ( req.url ~ "\?add-to-cart=" ) {
		return (pass);
	}

    # Don't cache admin
    if (req.url ~ "((wp-(login|admin|comments-post.php|cron.php))|login|timthumb|wrdp_files)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
        return (pass);
    } else {
        if ( !(req.http.cookie ~ "wpoven-no-cache") ) {
            unset req.http.cookie;
        }
    }
}

sub vcl_hit {
	# purge cached objects from memory
	if (req.request == "PURGE") {
			purge;
			error 200 "Purged";
	}
}

sub vcl_miss {
	# purge cached objects variants from memory
	if (req.request == "PURGE") {
		if (!client.ip ~ purge) {
			error 405 "Not allowed.";
		}
		ban("req.url ~ "+req.url);
		error 200 "Purged";
	}

	if (req.request == "PURGE") {
			purge;
			error 404 "Purged varients";
	}
}

sub vcl_fetch {
	# Dont cache admin
	if (req.url ~ "(wp-(login|admin|comments-post.php|cron.php))|login" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
		return (deliver);
	} else {
		if ( beresp.ttl > 0s && !(beresp.http.set-cookie ~ "wpoven-no-cache") ) {
			unset beresp.http.set-cookie;
		}
	}
}

sub vcl_deliver {
    # Remove unwanted headers
    unset resp.http.Server;
    unset resp.http.X-Powered-By;
    unset resp.http.x-backend;
    unset resp.http.Via;
    unset resp.http.X-Varnish;
}
