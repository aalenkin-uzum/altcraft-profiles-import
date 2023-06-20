SELECT json_agg(jsonb_strip_nulls(row_to_json(profile)::jsonb))
FROM (SELECT ke_contacts.last_name            AS _lname,
             ke_contacts.first_name           AS _fname,
             ke_contacts.birth_date           AS _bdate,
             ke_contacts.email                AS email,
             (CASE
                  WHEN ke_contacts.sex = 'MAN' THEN 1
                  WHEN ke_contacts.sex = 'WOMAN' THEN 2
                 END)                         AS _sex,
             ke_orders.order_address          AS order_address,
             ke_orders.last_order             AS last_order,
             dblink_account.phone_number      AS phones,
             dblink_account.uzum_customer_id  AS uzum_id,
             dblink_account.account_id        AS user_id,
             dblink_account.locale            AS "language",
             dblink_account.registration_date AS _regdate
      FROM public.contacts ke_contacts
               LEFT JOIN (SELECT order_subselect.contacts_id,
                                 MAX(order_subselect.date_created)                            AS last_order,
                                 jsonb_agg(DISTINCT order_subselect.delivery_point_id)
                                 filter (where order_subselect.delivery_point_id is not null) AS order_address
                          FROM public.order order_subselect
                          GROUP BY order_subselect.contacts_id) ke_orders
                         ON ke_orders.contacts_id = ke_contacts.id
               LEFT JOIN public.customer ke_customer ON ke_contacts.id = ke_customer.contacts_id
               LEFT JOIN (select account_id,
                                 string_to_array(phone_number, ',') AS phone_number,
                                 uzum_customer_id,
                                 locale,
                                 registration_date
                          FROM DBLINK(:'dblink_connection',
                                       'select account_id, phone_number, uzum_customer_id, locale, registration_date
                                       from public.account a LEFT JOIN public.customer c on a.id = c.account_id; ') acc (account_id int,
                                                                                                                         phone_number varchar(255),
                                                                                                                         uzum_customer_id varchar(255),
                                                                                                                         locale varchar(255),
                                                                                                                         registration_date timestamp)) dblink_account
                         ON dblink_account.account_id = ke_customer.account_id
      limit :limit_value offset :offset_value) profile;