--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ad_clicks; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE ad_clicks (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    ad_id integer NOT NULL,
    user_id integer,
    channel_id integer,
    page_type integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.ad_clicks OWNER TO ourstage;

--
-- Name: ad_clicks_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE ad_clicks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_clicks_id_seq OWNER TO ourstage;

--
-- Name: ad_clicks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE ad_clicks_id_seq OWNED BY ad_clicks.id;


--
-- Name: ad_impressions; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE ad_impressions (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    ad_id integer NOT NULL,
    user_id integer,
    channel_id integer,
    page_type integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.ad_impressions OWNER TO ourstage;

--
-- Name: ad_impressions_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE ad_impressions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_impressions_id_seq OWNER TO ourstage;

--
-- Name: ad_impressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE ad_impressions_id_seq OWNED BY ad_impressions.id;


--
-- Name: banner_hits; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE banner_hits (
    id integer NOT NULL,
    item_type integer NOT NULL,
    item character varying(255),
    style integer DEFAULT 0 NOT NULL,
    referrer character varying(255),
    action integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    ip_addr character varying(255),
    user_agent character varying(255)
);


ALTER TABLE public.banner_hits OWNER TO ourstage;

--
-- Name: banner_hits_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE banner_hits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.banner_hits_id_seq OWNER TO ourstage;

--
-- Name: banner_hits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE banner_hits_id_seq OWNED BY banner_hits.id;


--
-- Name: chatters; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE chatters (
    id integer NOT NULL,
    user_id integer,
    user_key character varying(12),
    room_id integer,
    room_key character varying(40),
    activity character varying(40),
    comment character varying(255),
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.chatters OWNER TO ourstage;

--
-- Name: chatters_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE chatters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.chatters_id_seq OWNER TO ourstage;

--
-- Name: chatters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE chatters_id_seq OWNED BY chatters.id;


--
-- Name: heartbeats; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE heartbeats (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    user_id integer,
    activity character varying(255),
    ip_addr character varying(255),
    referrer character varying(255),
    created_at timestamp without time zone NOT NULL,
    beat integer
);


ALTER TABLE public.heartbeats OWNER TO ourstage;

--
-- Name: heartbeats_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE heartbeats_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.heartbeats_id_seq OWNER TO ourstage;

--
-- Name: heartbeats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE heartbeats_id_seq OWNED BY heartbeats.id;


--
-- Name: media_views; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE media_views (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    player_key character varying(255) NOT NULL,
    sequence_num integer NOT NULL,
    media_key character varying(255) NOT NULL,
    entry_key character varying(255),
    media_type character varying(255) NOT NULL,
    playlist_key character varying(255),
    user_id integer,
    player_type character varying(255) NOT NULL,
    playlist_type character varying(255) NOT NULL,
    duration integer DEFAULT 0,
    referrer character varying(255),
    ip_addr character varying(255),
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.media_views OWNER TO ourstage;

--
-- Name: media_views_v1; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE media_views_v1 (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    player_key character varying(255) NOT NULL,
    sequence_num integer NOT NULL,
    media_key character varying(255) NOT NULL,
    entry_key character varying(255),
    media_type character varying(255) NOT NULL,
    playlist_key character varying(255),
    user_id integer,
    player_type character varying(255) NOT NULL,
    playlist_type character varying(255) NOT NULL,
    duration integer DEFAULT 0,
    referrer character varying(255),
    ip_addr character varying(255),
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.media_views_v1 OWNER TO ourstage;

--
-- Name: media_views_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE media_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.media_views_id_seq OWNER TO ourstage;

--
-- Name: media_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE media_views_id_seq OWNED BY media_views_v1.id;


--
-- Name: media_views_id_seq1; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE media_views_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.media_views_id_seq1 OWNER TO ourstage;

--
-- Name: media_views_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE media_views_id_seq1 OWNED BY media_views.id;


--
-- Name: ourband_page_views; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE ourband_page_views (
    id integer NOT NULL,
    user_id integer,
    profile_user_id integer NOT NULL,
    facebook_page_id character varying(255) NOT NULL,
    activity character varying(255),
    ip_addr character varying(255),
    comment character varying(255),
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.ourband_page_views OWNER TO ourstage;

--
-- Name: ourband_page_views_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE ourband_page_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ourband_page_views_id_seq OWNER TO ourstage;

--
-- Name: ourband_page_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE ourband_page_views_id_seq OWNED BY ourband_page_views.id;


--
-- Name: queue_tests; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE queue_tests (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    source character varying(255) NOT NULL,
    msg character varying(255) NOT NULL,
    sequence_num integer
);


ALTER TABLE public.queue_tests OWNER TO ourstage;

--
-- Name: queue_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE queue_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.queue_tests_id_seq OWNER TO ourstage;

--
-- Name: queue_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE queue_tests_id_seq OWNED BY queue_tests.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO ourstage;

--
-- Name: widget_hits; Type: TABLE; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE TABLE widget_hits (
    id integer NOT NULL,
    session_key character varying(255) NOT NULL,
    widget_key character varying(255) NOT NULL,
    giveaway_key character varying(255),
    referrer character varying(255),
    cycles integer DEFAULT 0 NOT NULL,
    phase integer NOT NULL,
    user_name character varying(255),
    activated_at timestamp without time zone,
    click_thru integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.widget_hits OWNER TO ourstage;

--
-- Name: widget_hits_id_seq; Type: SEQUENCE; Schema: public; Owner: ourstage
--

CREATE SEQUENCE widget_hits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.widget_hits_id_seq OWNER TO ourstage;

--
-- Name: widget_hits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ourstage
--

ALTER SEQUENCE widget_hits_id_seq OWNED BY widget_hits.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE ad_clicks ALTER COLUMN id SET DEFAULT nextval('ad_clicks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE ad_impressions ALTER COLUMN id SET DEFAULT nextval('ad_impressions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE banner_hits ALTER COLUMN id SET DEFAULT nextval('banner_hits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE chatters ALTER COLUMN id SET DEFAULT nextval('chatters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE heartbeats ALTER COLUMN id SET DEFAULT nextval('heartbeats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE media_views ALTER COLUMN id SET DEFAULT nextval('media_views_id_seq1'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE media_views_v1 ALTER COLUMN id SET DEFAULT nextval('media_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE ourband_page_views ALTER COLUMN id SET DEFAULT nextval('ourband_page_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE queue_tests ALTER COLUMN id SET DEFAULT nextval('queue_tests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ourstage
--

ALTER TABLE widget_hits ALTER COLUMN id SET DEFAULT nextval('widget_hits_id_seq'::regclass);


--
-- Name: ad_clicks_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY ad_clicks
    ADD CONSTRAINT ad_clicks_pkey PRIMARY KEY (id);


--
-- Name: ad_impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY ad_impressions
    ADD CONSTRAINT ad_impressions_pkey PRIMARY KEY (id);


--
-- Name: banner_hits_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY banner_hits
    ADD CONSTRAINT banner_hits_pkey PRIMARY KEY (id);


--
-- Name: chatters_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY chatters
    ADD CONSTRAINT chatters_pkey PRIMARY KEY (id);


--
-- Name: heartbeats_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY heartbeats
    ADD CONSTRAINT heartbeats_pkey PRIMARY KEY (id);


--
-- Name: media_views_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY media_views_v1
    ADD CONSTRAINT media_views_pkey PRIMARY KEY (id);


--
-- Name: media_views_pkey1; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY media_views
    ADD CONSTRAINT media_views_pkey1 PRIMARY KEY (id);


--
-- Name: ourband_page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY ourband_page_views
    ADD CONSTRAINT ourband_page_views_pkey PRIMARY KEY (id);


--
-- Name: queue_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY queue_tests
    ADD CONSTRAINT queue_tests_pkey PRIMARY KEY (id);


--
-- Name: widget_hits_pkey; Type: CONSTRAINT; Schema: public; Owner: ourstage; Tablespace: 
--

ALTER TABLE ONLY widget_hits
    ADD CONSTRAINT widget_hits_pkey PRIMARY KEY (id);


--
-- Name: index_media_views_on_created_at; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE INDEX index_media_views_on_created_at ON media_views USING btree (created_at);


--
-- Name: index_media_views_on_player_type; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE INDEX index_media_views_on_player_type ON media_views USING btree (player_type);


--
-- Name: index_media_views_on_referrer; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE INDEX index_media_views_on_referrer ON media_views USING btree (referrer);


--
-- Name: index_media_views_on_tons; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE UNIQUE INDEX index_media_views_on_tons ON media_views_v1 USING btree (session_id, player_key, sequence_num, media_key);


--
-- Name: index_widget_hits_on_tons; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE UNIQUE INDEX index_widget_hits_on_tons ON widget_hits USING btree (session_key, widget_key, giveaway_key);


--
-- Name: key_duration_date; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE INDEX key_duration_date ON media_views USING btree (media_key, duration, created_at);


--
-- Name: unique_media_view_index; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE UNIQUE INDEX unique_media_view_index ON media_views USING btree (session_id, player_key, sequence_num, media_key);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: ourstage; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

