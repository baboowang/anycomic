CREATE table IF NOT EXISTS shelf (
    book_id TEXT PRIMARY KEY,
    weight INTEGER DEFAULT 1,
    add_time INTEGER DEFAULT CURRENT_TIMESTAMP,
    last_period_update_time TEXT,
    FOREIGN KEY (book_id) REFERENCES book(id)
);

CREATE table IF NOT EXISTS site (
    id TEXT PRIMARY KEY,
    name TEXT,
    domain TEXT,
    config TEXT 
);

CREATE table IF NOT EXISTS book (
    id TEXT PRIMARY KEY,
    url TEXT,
    name TEXT,
    author TEXT,
    cates TEXT,
    area TEXT,
    status TEXT,
    update_time TEXT,
    last_update_period TEXT,
    intro TEXT,
    site_id TEXT,
    FOREIGN KEY (site_id) REFERENCES site(id)
);

CREATE table IF NOT EXISTS period (
    id TEXT PRIMARY KEY,
    url TEXT,
    name TEXT,
    page_count INTEGER,
    book_id TEXT,
    period_no INTEGER,
    FOREIGN KEY (book_id) REFERENCES book(id)
);

CREATE table IF NOT EXISTS page (
    id TEXT PRIMARY KEY,
    url TEXT,
    image_id TEXT,
    period_id TEXT,
    page_no INTEGER,
    FOREIGN KEY (period_id) REFERENCES period(id)
);

CREATE table IF NOT EXISTS cover (
    id TEXT PRIMARY KEY,
    url TEXT,
    image_id TEXT,
    book_id TEXT,
    FOREIGN KEY (book_id) REFERENCES book(id)
);

CREATE table IF NOT EXISTS image (
    id TEXT PRIMARY KEY,
    url TEXT,
    local_path TEXT
);

CREATE table IF NOT EXISTS read_log (
    book_id TEXT PRIMARY KEY,
    last_period_id TEXT,
    last_time INTEGER,
    FOREIGN KEY (book_id) REFERENCES book(id),
    FOREIGN KEY (last_period_id) REFERENCES period(id)
);
