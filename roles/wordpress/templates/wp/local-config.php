<?php
// ** MySQL settings ** //
/** The name of the database for WordPress */
define('DB_NAME', '{{ db }}');

/** MySQL database username */
define('DB_USER', '{{ db_user }}');

/** MySQL database password */
define('DB_PASSWORD', '{{ db_user_password }}');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

global $memecached_servers;

$memcached_servers = array(
    'default' => array(
        '127.0.0.1:11211'
    )
);

define('WP_CACHE_KEY_SALT', '{{ db }}_1');
