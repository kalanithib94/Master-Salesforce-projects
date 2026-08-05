| # | Area | Skill | API name | Why it is needed |
|---|------|-------|----------|------------------|
| 1 | Accounts | Create Account | create_account | Open a new company record after the user confirms the name and key fields. |
| 2 | Accounts | Get Account Details | fetch_account_details | Load the full account profile before updates, summaries, or next steps. |
| 3 | Accounts | Get Account Plan | fetch_account_plan | Load strategic plan and objectives for the account when the object exists. |
| 4 | Accounts | Get Account Related Records | fetch_account_related_lists | See contacts, opportunities, cases, and other children on the account. |
| 5 | Accounts | Search Accounts | fuzzy_search_accounts | Locate a company when the user gives a partial or spoken name. |
| 6 | Accounts | Update Account | update_account_fields | Change industry, address, phone, or other account data the user confirmed. |
| 7 | Contacts | Create Contact | create_contact | Add a person to Salesforce, usually under an existing account. |
| 8 | Contacts | Get Contact Details | fetch_contact_details | Load contact profile, title, and account link for outreach or updates. |
| 9 | Contacts | Get Contact Engagement History | fetch_contact_engagement_history | Timeline of recent tasks, meetings, and emails with the contact. |
| 10 | Contacts | Search Contacts | fuzzy_search_contacts | Find a person by name or email when the Salesforce Id is unknown. |
| 11 | Contacts | Update Contact | update_contact_fields | Correct email, phone, title, or other contact details after confirmation. |
| 12 | Leads | Convert Lead | convert_lead | Turn a qualified lead into account, contact, and optional opportunity. |
| 13 | Leads | Create Lead | create_lead | Capture a new prospect when there is no matching account yet. |
| 14 | Leads | Get Lead Details | fetch_lead_details | Load lead status, source, and company context for follow-up. |
| 15 | Leads | Search Leads | fuzzy_search_leads | Find a prospect by name or company before qualifying or converting. |
| 16 | Leads | Update Lead | update_lead_fields | Update lead status, score, or contact info during qualification. |
| 17 | Opportunities | Add Opportunity Contact Role | add_opportunity_contact_role | Link a contact to the deal with a role such as Decision Maker. |
| 18 | Opportunities | Add Opportunity Partner | add_opportunity_partner | Associate a partner account with a deal and role. |
| 19 | Opportunities | Add Opportunity Product | add_opportunity_line_item | Attach a priced product from the price book to the deal. |
| 20 | Opportunities | Add Opportunity Team Member | add_opportunity_team_member | Add a colleague to the deal with a team role. |
| 21 | Opportunities | Clone Opportunity | clone_opportunity | Duplicate a deal to start a related or renewal opportunity faster. |
| 22 | Opportunities | Create Opportunity | create_opportunity | Start a new deal with account, stage, and close date confirmed. |
| 23 | Opportunities | Get My Open Opportunities | fetch_my_open_opportunities | Pipeline view of the current user's open deals. |
| 24 | Opportunities | Get Opportunity Contact Roles | fetch_opportunity_contact_roles | See who on the buying committee is linked to the deal. |
| 25 | Opportunities | Get Opportunity Details | fetch_opportunity_details | Load stage, amount, close date, and deal context for review. |
| 26 | Opportunities | Get Opportunity Partners | fetch_opportunity_partners | List partners already tied to the opportunity. |
| 27 | Opportunities | Get Opportunity Team | fetch_opportunity_team | List internal sellers and specialists on the deal team. |
| 28 | Opportunities | Get Stale Opportunities | fetch_stale_opportunities | Surface deals with little recent activity that may need attention. |
| 29 | Opportunities | Search Opportunities | fuzzy_search_opportunities | Find a deal by name when the user cannot provide the Id. |
| 30 | Opportunities | Update Opportunity | update_opportunity_fields | Move stage, change amount or close date, or edit other deal fields. |
| 31 | Opportunities | Update Opportunity Contact Role | update_opportunity_contact_role | Change role or primary flag for someone on the deal. |
| 32 | Opportunities | Update Opportunity Product | update_opportunity_line_item | Adjust quantity, price, or discount on an existing product line. |
| 33 | Cases | Add Case Comment | add_case_comment | Post an internal or public update on the case thread. |
| 34 | Cases | Add Case Team Member | add_case_team_member | Bring another agent or specialist onto the case team. |
| 35 | Cases | Close Case | close_case | Resolve and close a ticket after the customer issue is handled. |
| 36 | Cases | Create Case | create_case | Open a support ticket linked to the right account or contact. |
| 37 | Cases | Get Case Details | fetch_case_details | Load case status, priority, and customer context for support work. |
| 38 | Cases | Get Case Team | fetch_case_team | See who is collaborating on the support case. |
| 39 | Cases | Link Knowledge Article to Case | link_knowledge_article_to_case | Attach a helpful article to the case for audit and deflection. |
| 40 | Cases | Search Cases | fuzzy_search_cases | Find a ticket by subject or case number from chat. |
| 41 | Cases | Update Case | update_case_fields | Change status, priority, owner, or other case fields mid-work. |
| 42 | Activities & Scheduling | Complete Task | complete_task | Mark a follow-up done after the work is finished. |
| 43 | Activities & Scheduling | Create Event | create_event | Book a meeting on the calendar linked to a person or record. |
| 44 | Activities & Scheduling | Create Task | create_task | Schedule a follow-up to-do with due date and owner. |
| 45 | Activities & Scheduling | Get My Open Tasks | fetch_my_open_tasks | Show the current user's incomplete to-dos for the day or week. |
| 46 | Activities & Scheduling | Log Activity | log_activity | Record a completed call, email, or note against any CRM record. |
| 47 | Activities & Scheduling | Update Event | update_event | Reschedule or edit meeting time, location, or notes. |
| 48 | Activities & Scheduling | Update Task | update_task | Reschedule, reassign, or edit an existing to-do. |
| 49 | Products & Price Books | Get Price Book Entries | fetch_pricebook_entries | Show list prices for products in a chosen or standard price book. |
| 50 | Products & Price Books | Get Product Details | fetch_product_details | Load product code, family, and description for configuration. |
| 51 | Products & Price Books | Search Products | fuzzy_search_products | Find a SKU or product name before adding lines to a deal or quote. |
| 52 | Campaigns | Add Campaign Member | add_campaign_member | Enroll a lead or contact into the campaign. |
| 53 | Campaigns | Create Campaign | create_campaign | Set up a new marketing campaign with name and schedule. |
| 54 | Campaigns | Get Campaign Details | fetch_campaign_details | Load campaign dates, type, status, and response counts. |
| 55 | Campaigns | Get Campaign Members | fetch_campaign_members | List who is already on the campaign and their status. |
| 56 | Campaigns | Remove Campaign Member | remove_campaign_member | Take a lead or contact off a campaign membership. |
| 57 | Campaigns | Search Campaigns | fuzzy_search_campaigns | Find a marketing campaign by name for member or status work. |
| 58 | Campaigns | Update Campaign | update_campaign_fields | Change campaign status, dates, or type after launch planning. |
| 59 | Campaigns | Update Campaign Member Status | update_campaign_member_status | Mark someone as Sent, Responded, or another member status. |
| 60 | Quotes | Add Quote Line Item | add_quote_line_item | Add a priced product line to the quote. |
| 61 | Quotes | Create Quote | create_quote | Create a standard quote for an opportunity. |
| 62 | Quotes | Get Quote Details | fetch_quote_details | Load quote header, status, and totals for review. |
| 63 | Quotes | Search Quotes | fuzzy_search_quotes | Find a quote by name when the quote number is unknown. |
| 64 | Quotes | Update Quote | update_quote_fields | Change quote status, expiration, or header fields. |
| 65 | Quotes | Update Quote Line Item | update_quote_line_item | Change quantity or price on an existing quote line. |
| 66 | CPQ | Add CPQ Quote Line | add_cpq_quote_line | Add a CPQ product or bundle line to the quote. |
| 67 | CPQ | Calculate CPQ Quote | calculate_cpq_quote | Run CPQ pricing so totals and discounts refresh. |
| 68 | CPQ | Create CPQ Quote | create_cpq_quote | Start a CPQ quote from an opportunity for guided selling. |
| 69 | CPQ | Get CPQ Quote Details | fetch_cpq_quote_details | Load Salesforce CPQ quote header and configuration context. |
| 70 | CPQ | Update CPQ Quote | update_cpq_quote_fields | Edit CPQ quote status or header fields before calculation. |
| 71 | CPQ | Update CPQ Quote Line | update_cpq_quote_line | Change quantity, options, or pricing on a CPQ line. |
| 72 | Contracts | Create Contract | create_contract | Create a contract record under the customer account. |
| 73 | Contracts | Get Contract Details | fetch_contract_details | Load contract status, term dates, and account linkage. |
| 74 | Contracts | Update Contract | update_contract_fields | Update contract status, dates, or terms after review. |
| 75 | Orders & Subscriptions | Add Order Product | add_order_item | Add a product line to the order. |
| 76 | Orders & Subscriptions | Create Order | create_order | Create an order from account or opportunity context. |
| 77 | Orders & Subscriptions | Get Order Details | fetch_order_details | Load order status, account, and totals after win or fulfillment. |
| 78 | Orders & Subscriptions | Get Subscription Details | fetch_subscription_details | Load subscription term, quantity, and billing status. |
| 79 | Orders & Subscriptions | Update Order | update_order_fields | Update order status or header fields during fulfillment. |
| 80 | Orders & Subscriptions | Update Order Product | update_order_item | Adjust quantity or price on an order line. |
| 81 | Orders & Subscriptions | Update Subscription | update_subscription_fields | Change subscription quantity, term, or status fields. |
| 82 | Renewals | Get Renewal Opportunities | fetch_renewal_opportunities | List open renewal-type deals for pipeline or CSM review. |
| 83 | Renewals | Get Upcoming Renewals | fetch_upcoming_renewals | Show renewals closing within the next N days for outreach planning. |
| 84 | Service Cloud | Assign Record to Queue | assign_to_queue | Route a record into a work queue for the next available agent. |
| 85 | Service Cloud | Get Asset Details | fetch_asset_details | Load asset status, account, and product information. |
| 86 | Service Cloud | Get Case Entitlements | fetch_case_entitlements | See support coverage and entitlement levels for the customer. |
| 87 | Service Cloud | Get Case Milestones | fetch_case_milestones | Check SLA milestone progress and breach risk on the case. |
| 88 | Service Cloud | Get Knowledge Article | fetch_knowledge_article | Open the full article body for use in a reply. |
| 89 | Service Cloud | Get Queue Cases | fetch_queue_cases | List cases waiting in a specific support queue. |
| 90 | Service Cloud | Search Assets | fuzzy_search_assets | Find installed equipment by name or serial number. |
| 91 | Service Cloud | Search Knowledge Articles | search_knowledge_articles | Find KB articles that may answer the customer's question. |
| 92 | Service Cloud | Update Asset | update_asset_fields | Update asset status, location, or warranty-related fields. |
| 93 | Field Service | Create Work Order | create_work_order | Open a work order for on-site or remote service. |
| 94 | Field Service | Get Resource Availability | fetch_service_resource_availability | Check when a technician or resource is free to schedule. |
| 95 | Field Service | Get Service Appointment | fetch_service_appointment | Load appointment time window and assigned resource. |
| 96 | Field Service | Get Work Order Details | fetch_work_order_details | Load field service work order status and related customer data. |
| 97 | Field Service | Schedule Service Appointment | schedule_service_appointment | Set or change when a technician visit is booked. |
| 98 | Field Service | Update Service Appointment | update_service_appointment | Edit appointment status, time, or assignment details. |
| 99 | Field Service | Update Work Order | update_work_order_fields | Change work order status, priority, or schedule fields. |
| 100 | Partner Management | Get Partner Account Details | fetch_partner_account | Load partner account profile and relationship details. |
| 101 | Partner Management | Search Partner Accounts | fuzzy_search_partners | Find partner accounts by name for deal registration or teaming. |
| 102 | Industry Clouds | Create Care Task | create_care_task | Add a care-plan task for clinical or care-team follow-up. |
| 103 | Industry Clouds | Get Care Plan | fetch_care_plan | Load a Health Cloud care plan and related goals when available. |
| 104 | Industry Clouds | Get Financial Account | fetch_financial_account | Load FSC financial account balances and ownership when licensed. |
| 105 | Industry Clouds | Update Care Plan | update_care_plan_fields | Update care plan status or dates in Health Cloud orgs. |
| 106 | Industry Clouds | Update Financial Account | update_financial_account_fields | Update financial account status or attributes in FSC orgs. |
| 107 | Platform & Insights | Get Picklist Values | fetch_picklist_values | List valid choices for a field before setting a picklist value. |
| 108 | Platform & Insights | Get Record Approvals | fetch_record_approvals | See pending approval requests and submitters on a record. |
| 109 | Platform & Insights | Get Session Context | fetch_session_context | See which record and related people the chat is on, so the agent can act without asking for Ids. Use before updates, summaries, logging activity, or drafting follow-ups. |
| 110 | Platform & Insights | Run a GPTfy prompt | run_internal_prompt | Generate a 360, summary, meeting prep, or draft from record data. |
| 111 | Platform & Insights | Transfer Record Owner | transfer_record_owner | Reassign ownership of a record to another user. |

**Total: 111 skills**