SELECT count(*)
FROM (SELECT ke_contacts.id
      FROM public.contacts ke_contacts
               LEFT JOIN (SELECT order_subselect.contacts_id
                          FROM public.order order_subselect
                          GROUP BY order_subselect.contacts_id) ke_orders
                         ON ke_orders.contacts_id = ke_contacts.id
               LEFT JOIN public.customer ke_customer ON ke_contacts.id = ke_customer.contacts_id
               LEFT JOIN (select account_id
                          FROM DBLINK(:'dblink_connection',
                                      ' select account_id from public.account a LEFT JOIN public.customer c on a.id = c.account_id; ') acc (account_id int)) dblink_account
                         ON dblink_account.account_id = ke_customer.account_id) profile;