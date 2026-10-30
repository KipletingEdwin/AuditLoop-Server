SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: enforce_refund_cap(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_refund_cap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  charge_total integer;
  already_refunded integer;
BEGIN
  SELECT amount_cents INTO charge_total FROM charges WHERE id = NEW.charge_id FOR UPDATE;
  SELECT COALESCE(SUM(amount_cents), 0) INTO already_refunded
    FROM refunds WHERE charge_id = NEW.charge_id AND status <> 'failed';

  IF already_refunded + NEW.amount_cents > charge_total THEN
    RAISE EXCEPTION 'refunds would exceed charge amount' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: events_append_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.events_append_only() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'events is append-only';
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    name character varying NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: agent_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_runs (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    llm_model character varying NOT NULL,
    prompt_version character varying NOT NULL,
    status character varying DEFAULT 'running'::character varying NOT NULL,
    input_tokens integer DEFAULT 0 NOT NULL,
    output_tokens integer DEFAULT 0 NOT NULL,
    started_at timestamp(6) without time zone NOT NULL,
    finished_at timestamp(6) without time zone,
    error text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT agent_runs_status_valid CHECK (((status)::text = ANY ((ARRAY['running'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: agent_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_runs_id_seq OWNED BY public.agent_runs.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.charges (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    subscription_id bigint,
    external_id character varying NOT NULL,
    amount_cents integer NOT NULL,
    currency character varying DEFAULT 'usd'::character varying NOT NULL,
    status character varying NOT NULL,
    description character varying,
    charged_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT charges_amount_positive CHECK ((amount_cents > 0)),
    CONSTRAINT charges_status_valid CHECK (((status)::text = ANY (ARRAY[('succeeded'::character varying)::text, ('pending'::character varying)::text, ('failed'::character varying)::text])))
);


--
-- Name: charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.charges_id_seq OWNED BY public.charges.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    external_id character varying NOT NULL,
    email character varying NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    ticket_id bigint,
    actor_type character varying NOT NULL,
    actor_id bigint,
    name character varying NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT events_actor_type_valid CHECK (((actor_type)::text = ANY (ARRAY[('user'::character varying)::text, ('agent'::character varying)::text, ('system'::character varying)::text])))
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: proposals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposals (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    agent_run_id bigint NOT NULL,
    action character varying NOT NULL,
    charge_id bigint,
    amount_cents integer,
    currency character varying DEFAULT 'usd'::character varying,
    reasoning text NOT NULL,
    confidence numeric(3,2),
    evidence jsonb DEFAULT '[]'::jsonb NOT NULL,
    policy_result jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT proposals_action_valid CHECK (((action)::text = ANY ((ARRAY['refund'::character varying, 'partial_refund'::character varying, 'no_action'::character varying, 'escalate'::character varying])::text[]))),
    CONSTRAINT proposals_confidence_range CHECK (((confidence IS NULL) OR ((confidence >= (0)::numeric) AND (confidence <= (1)::numeric)))),
    CONSTRAINT proposals_refund_has_charge_and_amount CHECK ((((action)::text <> ALL ((ARRAY['refund'::character varying, 'partial_refund'::character varying])::text[])) OR ((charge_id IS NOT NULL) AND (amount_cents > 0))))
);


--
-- Name: proposals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proposals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proposals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proposals_id_seq OWNED BY public.proposals.id;


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_digest character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refresh_tokens_id_seq OWNED BY public.refresh_tokens.id;


--
-- Name: refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refunds (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    charge_id bigint NOT NULL,
    proposal_id bigint NOT NULL,
    external_id character varying,
    amount_cents integer NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    idempotency_key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT refunds_amount_positive CHECK ((amount_cents > 0)),
    CONSTRAINT refunds_status_valid CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'succeeded'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: refunds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refunds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refunds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refunds_id_seq OWNED BY public.refunds.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    proposal_id bigint NOT NULL,
    user_id bigint NOT NULL,
    decision character varying NOT NULL,
    final_amount_cents integer,
    rejection_reason text,
    reviewed_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT reviews_decision_valid CHECK (((decision)::text = ANY ((ARRAY['approved'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT reviews_rejection_needs_reason CHECK ((((decision)::text <> 'rejected'::text) OR (rejection_reason IS NOT NULL)))
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    external_id character varying NOT NULL,
    plan_name character varying NOT NULL,
    amount_cents integer NOT NULL,
    status character varying NOT NULL,
    canceled_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT subscriptions_amount_nonneg CHECK ((amount_cents >= 0)),
    CONSTRAINT subscriptions_status_valid CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('canceled'::character varying)::text, ('past_due'::character varying)::text])))
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    customer_id bigint,
    from_email character varying NOT NULL,
    subject character varying NOT NULL,
    body text NOT NULL,
    received_at timestamp(6) without time zone NOT NULL,
    state character varying DEFAULT 'received'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT tickets_state_valid CHECK (((state)::text = ANY (ARRAY[('received'::character varying)::text, ('investigating'::character varying)::text, ('proposed'::character varying)::text, ('pending_approval'::character varying)::text, ('approved'::character varying)::text, ('rejected'::character varying)::text, ('executed'::character varying)::text, ('failed'::character varying)::text])))
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- Name: tool_calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_calls (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    agent_run_id bigint NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    input jsonb DEFAULT '{}'::jsonb NOT NULL,
    output jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tool_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tool_calls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tool_calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tool_calls_id_seq OWNED BY public.tool_calls.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    role character varying DEFAULT 'reviewer'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT users_role_valid CHECK (((role)::text = ANY (ARRAY[('reviewer'::character varying)::text, ('manager'::character varying)::text, ('admin'::character varying)::text])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: agent_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs ALTER COLUMN id SET DEFAULT nextval('public.agent_runs_id_seq'::regclass);


--
-- Name: charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.charges ALTER COLUMN id SET DEFAULT nextval('public.charges_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: proposals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals ALTER COLUMN id SET DEFAULT nextval('public.proposals_id_seq'::regclass);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('public.refresh_tokens_id_seq'::regclass);


--
-- Name: refunds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds ALTER COLUMN id SET DEFAULT nextval('public.refunds_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- Name: tool_calls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls ALTER COLUMN id SET DEFAULT nextval('public.tool_calls_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: agent_runs agent_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: charges charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.charges
    ADD CONSTRAINT charges_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: proposals proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tool_calls tool_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT tool_calls_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_agent_runs_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_runs_on_account_id ON public.agent_runs USING btree (account_id);


--
-- Name: index_agent_runs_on_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_runs_on_ticket_id ON public.agent_runs USING btree (ticket_id);


--
-- Name: index_charges_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_charges_on_account_id ON public.charges USING btree (account_id);


--
-- Name: index_charges_on_account_id_and_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_charges_on_account_id_and_external_id ON public.charges USING btree (account_id, external_id);


--
-- Name: index_charges_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_charges_on_customer_id ON public.charges USING btree (customer_id);


--
-- Name: index_charges_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_charges_on_subscription_id ON public.charges USING btree (subscription_id);


--
-- Name: index_customers_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customers_on_account_id ON public.customers USING btree (account_id);


--
-- Name: index_customers_on_account_id_and_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customers_on_account_id_and_email ON public.customers USING btree (account_id, email);


--
-- Name: index_customers_on_account_id_and_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_customers_on_account_id_and_external_id ON public.customers USING btree (account_id, external_id);


--
-- Name: index_events_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_account_id ON public.events USING btree (account_id);


--
-- Name: index_events_on_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_ticket_id ON public.events USING btree (ticket_id);


--
-- Name: index_events_on_ticket_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_ticket_id_and_created_at ON public.events USING btree (ticket_id, created_at);


--
-- Name: index_proposals_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_proposals_on_account_id ON public.proposals USING btree (account_id);


--
-- Name: index_proposals_on_agent_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_proposals_on_agent_run_id ON public.proposals USING btree (agent_run_id);


--
-- Name: index_proposals_on_charge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_proposals_on_charge_id ON public.proposals USING btree (charge_id);


--
-- Name: index_proposals_on_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_proposals_on_ticket_id ON public.proposals USING btree (ticket_id);


--
-- Name: index_refresh_tokens_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_refresh_tokens_on_token_digest ON public.refresh_tokens USING btree (token_digest);


--
-- Name: index_refresh_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refresh_tokens_on_user_id ON public.refresh_tokens USING btree (user_id);


--
-- Name: index_refunds_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_account_id ON public.refunds USING btree (account_id);


--
-- Name: index_refunds_on_charge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_charge_id ON public.refunds USING btree (charge_id);


--
-- Name: index_refunds_on_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_refunds_on_idempotency_key ON public.refunds USING btree (idempotency_key);


--
-- Name: index_refunds_on_proposal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_proposal_id ON public.refunds USING btree (proposal_id);


--
-- Name: index_reviews_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_account_id ON public.reviews USING btree (account_id);


--
-- Name: index_reviews_on_proposal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reviews_on_proposal_id ON public.reviews USING btree (proposal_id);


--
-- Name: index_reviews_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_user_id ON public.reviews USING btree (user_id);


--
-- Name: index_subscriptions_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_account_id ON public.subscriptions USING btree (account_id);


--
-- Name: index_subscriptions_on_account_id_and_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscriptions_on_account_id_and_external_id ON public.subscriptions USING btree (account_id, external_id);


--
-- Name: index_subscriptions_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_customer_id ON public.subscriptions USING btree (customer_id);


--
-- Name: index_tickets_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_account_id ON public.tickets USING btree (account_id);


--
-- Name: index_tickets_on_account_id_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_account_id_and_state ON public.tickets USING btree (account_id, state);


--
-- Name: index_tickets_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_customer_id ON public.tickets USING btree (customer_id);


--
-- Name: index_tool_calls_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tool_calls_on_account_id ON public.tool_calls USING btree (account_id);


--
-- Name: index_tool_calls_on_agent_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tool_calls_on_agent_run_id ON public.tool_calls USING btree (agent_run_id);


--
-- Name: index_tool_calls_on_agent_run_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tool_calls_on_agent_run_id_and_position ON public.tool_calls USING btree (agent_run_id, "position");


--
-- Name: index_users_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_account_id ON public.users USING btree (account_id);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: events events_no_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER events_no_truncate BEFORE TRUNCATE ON public.events FOR EACH STATEMENT EXECUTE FUNCTION public.events_append_only();


--
-- Name: events events_no_update_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER events_no_update_delete BEFORE DELETE OR UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.events_append_only();


--
-- Name: refunds refunds_cap_check; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER refunds_cap_check BEFORE INSERT ON public.refunds FOR EACH ROW EXECUTE FUNCTION public.enforce_refund_cap();


--
-- Name: events fk_rails_17c5f28626; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_17c5f28626 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: tool_calls fk_rails_1f2f92b9d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT fk_rails_1f2f92b9d6 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: refunds fk_rails_23a510233b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_rails_23a510233b FOREIGN KEY (charge_id) REFERENCES public.charges(id);


--
-- Name: refresh_tokens fk_rails_279e9a0091; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT fk_rails_279e9a0091 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: proposals fk_rails_412bed11dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT fk_rails_412bed11dd FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: tickets fk_rails_4206602c73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_rails_4206602c73 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: refunds fk_rails_443993ebd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_rails_443993ebd1 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: tickets fk_rails_5685ed71b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_rails_5685ed71b0 FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: users fk_rails_61ac11da2b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_61ac11da2b FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: subscriptions fk_rails_66eb6b32c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_66eb6b32c1 FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: proposals fk_rails_687978492a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT fk_rails_687978492a FOREIGN KEY (charge_id) REFERENCES public.charges(id);


--
-- Name: agent_runs fk_rails_6eef70e698; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT fk_rails_6eef70e698 FOREIGN KEY (ticket_id) REFERENCES public.tickets(id);


--
-- Name: charges fk_rails_7422c2ed13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.charges
    ADD CONSTRAINT fk_rails_7422c2ed13 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: reviews fk_rails_74a66bd6c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_74a66bd6c5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: refunds fk_rails_855c837742; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_rails_855c837742 FOREIGN KEY (proposal_id) REFERENCES public.proposals(id);


--
-- Name: agent_runs fk_rails_9393f2f1b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT fk_rails_9393f2f1b6 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: proposals fk_rails_ad08996d25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT fk_rails_ad08996d25 FOREIGN KEY (ticket_id) REFERENCES public.tickets(id);


--
-- Name: proposals fk_rails_c77e18b093; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT fk_rails_c77e18b093 FOREIGN KEY (agent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: events fk_rails_c78acf8e79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_c78acf8e79 FOREIGN KEY (ticket_id) REFERENCES public.tickets(id);


--
-- Name: reviews fk_rails_ca4fbd7e26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_ca4fbd7e26 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: tool_calls fk_rails_cc11d0226e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT fk_rails_cc11d0226e FOREIGN KEY (agent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: charges fk_rails_d9fa190624; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.charges
    ADD CONSTRAINT fk_rails_d9fa190624 FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: reviews fk_rails_dc4330e83c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_dc4330e83c FOREIGN KEY (proposal_id) REFERENCES public.proposals(id);


--
-- Name: subscriptions fk_rails_eb0e3ffd90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_eb0e3ffd90 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: customers fk_rails_ed7ccfecee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT fk_rails_ed7ccfecee FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: charges fk_rails_f9da65bc10; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.charges
    ADD CONSTRAINT fk_rails_f9da65bc10 FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261030162951'),
('20261030162939'),
('20261030162922'),
('20261030162904'),
('20261030162844'),
('20261030162818'),
('20261030132554'),
('20261030132536'),
('20261030132514'),
('20261030132449'),
('20261030132410'),
('20261030132346'),
('20261029140107'),
('20261029135923'),
('20261029135639');

