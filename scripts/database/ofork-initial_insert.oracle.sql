-- ----------------------------------------------------------
--  driver: oracle
-- ----------------------------------------------------------
SET DEFINE OFF;
SET SQLBLANKLINES ON;
-- ----------------------------------------------------------
--  insert into table valid
-- ----------------------------------------------------------
INSERT INTO valid (name, create_by, create_time, change_by, change_time)
    VALUES
    ('valid', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table valid
-- ----------------------------------------------------------
INSERT INTO valid (name, create_by, create_time, change_by, change_time)
    VALUES
    ('invalid', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table valid
-- ----------------------------------------------------------
INSERT INTO valid (name, create_by, create_time, change_by, change_time)
    VALUES
    ('invalid-temporarily', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table users
-- ----------------------------------------------------------
INSERT INTO users (first_name, last_name, login, pw, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Admin', 'OFORK', 'root@localhost', 'roK20XGbWEsSM', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('users', 'Group for default access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('admin', 'Group of all administrators.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('RoomBooking', 'Group for room booking access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('stats', 'Group for statistics access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TimeTracking', 'Group for time tracking access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TimeTrackingEvaluation', 'Group for time tracking evaluation access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ProcessManager', 'Group for ProcessManager access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table groups
-- ----------------------------------------------------------
INSERT INTO groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ContractManager', 'Group for ContractManager access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table group_user
-- ----------------------------------------------------------
INSERT INTO group_user (user_id, group_id, permission_key, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 'rw', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table group_user
-- ----------------------------------------------------------
INSERT INTO group_user (user_id, group_id, permission_key, create_by, create_time, change_by, change_time)
    VALUES
    (1, 2, 'rw', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table group_user
-- ----------------------------------------------------------
INSERT INTO group_user (user_id, group_id, permission_key, create_by, create_time, change_by, change_time)
    VALUES
    (1, 3, 'rw', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_type
-- ----------------------------------------------------------
INSERT INTO link_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Normal', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_type
-- ----------------------------------------------------------
INSERT INTO link_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ParentChild', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_state
-- ----------------------------------------------------------
INSERT INTO link_state (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Valid', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_state
-- ----------------------------------------------------------
INSERT INTO link_state (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Temporary', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('new', 'All new state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('open', 'All open state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('closed', 'All closed state types (default: not viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('pending reminder', 'All ''pending reminder'' state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('pending auto', 'All ''pending auto *'' state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('removed', 'All ''removed'' state types (default: not viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('merged', 'State type for merged tickets (default: not viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('new', 'New ticket created by customer.', 1, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('closed successful', 'Ticket is closed successful.', 3, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('closed unsuccessful', 'Ticket is closed unsuccessful.', 3, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('open', 'Open tickets.', 2, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('removed', 'Customer removed ticket.', 6, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('pending reminder', 'Ticket is pending for agent reminder.', 4, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('pending auto close+', 'Ticket is pending for automatic close.', 5, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('pending auto close-', 'Ticket is pending for automatic close.', 5, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('merged', 'State for merged tickets.', 7, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table salutation
-- ----------------------------------------------------------
INSERT INTO salutation (name, text, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('system standard salutation (en)', 'Dear <OFORK_CUSTOMER_REALNAME>,

Thank you for your request.

', 'text/plain; charset=utf-8', 'Standard Salutation.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table signature
-- ----------------------------------------------------------
INSERT INTO signature (name, text, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('system standard signature (en)', '
Your Ticket-Team

 <OFORK_Agent_UserFirstname> <OFORK_Agent_UserLastname>

--
 Super Support - Waterford Business Park
 5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
 Email: hot@example.com - Web: http://www.example.com/
--', 'text/plain; charset=utf-8', 'Standard Signature.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table system_address
-- ----------------------------------------------------------
INSERT INTO system_address (value0, value1, comments, valid_id, queue_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ofork@localhost', 'OFORK System', 'Standard Address.', 1, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table follow_up_possible
-- ----------------------------------------------------------
INSERT INTO follow_up_possible (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('possible', 'Follow-ups for closed tickets are possible. Ticket will be reopened.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table follow_up_possible
-- ----------------------------------------------------------
INSERT INTO follow_up_possible (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('reject', 'Follow-ups for closed tickets are not possible. No new ticket will be created.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table follow_up_possible
-- ----------------------------------------------------------
INSERT INTO follow_up_possible (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('new ticket', 'Follow-ups for closed tickets are not possible. A new ticket will be created.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Postmaster', 1, 1, 1, 1, 1, 0, 0, 'Postmaster queue.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Raw', 1, 1, 1, 1, 1, 0, 0, 'All default incoming tickets.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Junk', 1, 1, 1, 1, 1, 0, 0, 'All junk tickets.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Misc', 1, 1, 1, 1, 1, 0, 0, 'All misc tickets.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table standard_template
-- ----------------------------------------------------------
INSERT INTO standard_template (name, text, content_type, template_type, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('empty answer', '', 'text/plain; charset=utf-8', 'Answer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table standard_template
-- ----------------------------------------------------------
INSERT INTO standard_template (name, text, content_type, template_type, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('test answer', 'Some test answer to show how a standard template can be used.', 'text/plain; charset=utf-8', 'Answer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (2, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (3, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (4, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto reply', 'Automatic reply which will be sent out after a new ticket has been created.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto reject', 'Automatic reject which will be sent out after a follow-up has been rejected (in case queue follow-up option is "reject").', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto follow up', 'Automatic confirmation which is sent out after a follow-up has been received for a ticket (in case queue follow-up option is "possible").', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto reply/new ticket', 'Automatic response which will be sent out after a follow-up has been rejected and a new ticket has been created (in case queue follow-up option is "new ticket").', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto remove', 'Auto remove will be sent out after a customer removed the request.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 'default reply (after new ticket has been created)', 'This is a demo text which is send to every inquiry.
It could contain something like:

Thanks for your email. A new ticket has been created.

You wrote:
<OFORK_CUSTOMER_EMAIL[6]>

Your email will be answered by a human ASAP

Have fun with OFORK! :-)

Your OFORK Team
', 'RE: <OFORK_CUSTOMER_SUBJECT[24]>', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (2, 1, 'default reject (after follow-up and rejected of a closed ticket)', 'Your previous ticket is closed.

-- Your follow-up has been rejected. --

Please create a new ticket.

Your OFORK Team
', 'Your email has been rejected! (RE: <OFORK_CUSTOMER_SUBJECT[24]>)', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (3, 1, 'default follow-up (after a ticket follow-up has been added)', 'Thanks for your follow-up email

You wrote:
<OFORK_CUSTOMER_EMAIL[6]>

Your email will be answered by a human ASAP.

Have fun with OFORK!

Your OFORK Team
', 'RE: <OFORK_CUSTOMER_SUBJECT[24]>', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (4, 1, 'default reject/new ticket created (after closed follow-up with new ticket creation)', 'Your previous ticket is closed.

-- A new ticket has been created for you. --

You wrote:
<OFORK_CUSTOMER_EMAIL[6]>

Your email will be answered by a human ASAP.

Have fun with OFORK!

Your OFORK Team
', 'New ticket has been created! (RE: <OFORK_CUSTOMER_SUBJECT[24]>)', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_type
-- ----------------------------------------------------------
INSERT INTO ticket_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Unclassified', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_type
-- ----------------------------------------------------------
INSERT INTO ticket_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('RoomBooking', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('1 very low', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('2 low', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('3 normal', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('4 high', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('5 very high', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_lock_type
-- ----------------------------------------------------------
INSERT INTO ticket_lock_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('unlock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_lock_type
-- ----------------------------------------------------------
INSERT INTO ticket_lock_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('lock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_lock_type
-- ----------------------------------------------------------
INSERT INTO ticket_lock_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('tmp_lock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('NewTicket', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('FollowUp', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAutoReject', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAutoReply', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAutoFollowUp', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Forward', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Bounce', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAnswer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAgentNotification', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendCustomerNotification', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EmailAgent', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EmailCustomer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('PhoneCallAgent', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('PhoneCallCustomer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('AddNote', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Move', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Lock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Unlock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Remove', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TimeAccounting', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('CustomerUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('PriorityUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('OwnerUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('LoopProtection', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Misc', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SetPendingTime', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('StateUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TicketDynamicFieldUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('WebRequestCustomer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TicketLinkAdd', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TicketLinkDelete', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SystemRequest', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Merged', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ResponsibleUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Subscribe', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Unsubscribe', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TypeUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ServiceUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SLAUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ArchiveFlagUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationSolutionTimeStop', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationResponseTimeStart', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationUpdateTimeStart', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationSolutionTimeStart', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationResponseTimeNotifyBefore', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationUpdateTimeNotifyBefore', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationSolutionTimeNotifyBefore', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationResponseTimeStop', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationUpdateTimeStop', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TitleUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EmailResend', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_sender_type
-- ----------------------------------------------------------
INSERT INTO article_sender_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('agent', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_sender_type
-- ----------------------------------------------------------
INSERT INTO article_sender_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('system', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_sender_type
-- ----------------------------------------------------------
INSERT INTO article_sender_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('customer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket
-- ----------------------------------------------------------
INSERT INTO ticket (tn, queue_id, ticket_lock_id, user_id, responsible_user_id, ticket_priority_id, ticket_state_id, title, timeout, until_time, escalation_time, escalation_response_time, escalation_update_time, escalation_solution_time, create_by, create_time, change_by, change_time)
    VALUES
    ('2015071510123456', 2, 1, 1, 1, 3, 1, 'Welcome to OFORK!', 0, 0, 0, 0, 0, 0, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Email', 'Kernel::System::CommunicationChannel::Email', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Phone', 'Kernel::System::CommunicationChannel::Phone', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Internal', 'Kernel::System::CommunicationChannel::Internal', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Chat', 'Kernel::System::CommunicationChannel::Chat', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_ofork_chat
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article
-- ----------------------------------------------------------
INSERT INTO article (ticket_id, communication_channel_id, article_sender_type_id, is_visible_for_customer, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 3, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_data_mime
-- ----------------------------------------------------------
INSERT INTO article_data_mime (article_id, a_from, a_to, a_subject, a_body, a_message_id, incoming_time, content_path, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'OFORK Feedback <support@o-fork.de>', 'Your OFORK System <ofork@localhost>', 'Welcome to OFORK!', 'Welcome to OFORK!

Thank you for installing OFORK.

You can find updates and patches for OFORK at
https://o-fork.de/Download.html

Find more information about it at https://o-fork.de/.

Best regards and ((enjoy)) OFORK,

Your OFORK Team
', '<007@localhost>', 1436949030, '2015/07/15', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_data_mime_plain
-- ----------------------------------------------------------
INSERT INTO article_data_mime_plain (article_id, body, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'From: OFORK Feedback <support@o-fork.de>
To: Your OFORK System <ofork@localhost>
Subject: Welcome to OFORK!
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

Welcome to OFORK!

Thank you for installing OFORK

You can find updates and patches for OFORK at
https://o-fork.de/Download.html

Find more information about it at https://o-fork.de/.

Best regards and ((enjoy)) OFORK,

Your OFORK Team
', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history
-- ----------------------------------------------------------
INSERT INTO ticket_history (name, history_type_id, ticket_id, type_id, article_id, priority_id, owner_id, state_id, queue_id, create_by, create_time, change_by, change_time)
    VALUES
    ('New Ticket [2015071510123456] created.', 1, 1, 1, 1, 3, 1, 1, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket create notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'VisibleForAgentTooltip', 'You will receive a notification each time a new ticket is created in one of your "My Queues" or "My Services".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Events', 'NotificationNewTicket');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Recipients', 'AgentMyServices');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket follow-up notification (unlocked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'VisibleForAgentTooltip', 'You will receive a notification if a customer sends a follow-up to an unlocked ticket which is in your "My Queues" or "My Services".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Events', 'NotificationFollowUp');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentWatcher');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentMyServices');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'LockID', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket follow-up notification (locked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'VisibleForAgentTooltip', 'You will receive a notification if a customer sends a follow-up to a locked ticket of which you are the ticket owner or responsible.');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Events', 'NotificationFollowUp');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Recipients', 'AgentWatcher');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'LockID', '2');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'LockID', '3');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket lock timeout notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'VisibleForAgentTooltip', 'You will receive a notification as soon as a ticket owned by you is automatically unlocked.');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'Events', 'NotificationLockTimeout');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket owner update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'Events', 'NotificationOwnerUpdate');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket responsible update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'Events', 'NotificationResponsibleUpdate');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket new note notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Events', 'NotificationAddNote');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Recipients', 'AgentWatcher');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket queue update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'VisibleForAgentTooltip', 'You will receive a notification if a ticket is moved into one of your "My Queues".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'Events', 'NotificationMove');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket pending reminder notification (locked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Events', 'NotificationPendingReminder');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'LockID', '2');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'LockID', '3');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket pending reminder notification (unlocked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Events', 'NotificationPendingReminder');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'LockID', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket escalation notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Events', 'NotificationEscalation');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Recipients', 'AgentWritePermissions');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket escalation warning notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Events', 'NotificationEscalationNotifyBefore');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Recipients', 'AgentWritePermissions');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket service update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'VisibleForAgentTooltip', 'You will receive a notification if a ticket''s service is changed to one of your "My Services".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'Events', 'NotificationServiceUpdate');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'Recipients', 'AgentMyServices');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Appointment reminder notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'VisibleForAgentTooltip', 'You will receive a notification each time a reminder time is reached for one of your appointments.');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'Events', 'AppointmentNotification');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'Recipients', 'AppointmentAgentReadPermissions');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'NotificationType', 'Appointment');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket email delivery failure notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'ArticleAttachmentInclude', '0');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'ArticleCommunicationChannelID', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Events', 'ArticleEmailSendingError');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'LanguageID', 'en');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'RecipientGroups', '2');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'TransportEmailTemplate', 'Default');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'VisibleForAgent', '0');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'en', 'Ticket Created: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has been created in queue <OFORK_TICKET_Queue>.

<OFORK_CUSTOMER_REALNAME> wrote:
<OFORK_CUSTOMER_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'en', 'Unlocked Ticket Follow-Up: <OFORK_CUSTOMER_SUBJECT[24]>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

the unlocked ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] received a follow-up.

<OFORK_CUSTOMER_REALNAME> wrote:
<OFORK_CUSTOMER_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'en', 'Locked Ticket Follow-Up: <OFORK_CUSTOMER_SUBJECT[24]>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

the locked ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] received a follow-up.

<OFORK_CUSTOMER_REALNAME> wrote:
<OFORK_CUSTOMER_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'en', 'Ticket Lock Timeout: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has reached its lock timeout period and is now unlocked.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'en', 'Ticket Owner Update to <OFORK_OWNER_UserFullname>: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

the owner of ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has been updated to <OFORK_TICKET_OWNER_UserFullname> by <OFORK_CURRENT_UserFullname>.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'en', 'Ticket Responsible Update to <OFORK_RESPONSIBLE_UserFullname>: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

the responsible agent of ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has been updated to <OFORK_TICKET_RESPONSIBLE_UserFullname> by <OFORK_CURRENT_UserFullname>.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'en', 'Ticket Note: <OFORK_AGENT_SUBJECT[24]>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

<OFORK_CURRENT_UserFullname> wrote:
<OFORK_AGENT_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'en', 'Ticket Queue Update to <OFORK_TICKET_Queue>: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has been updated to queue <OFORK_TICKET_Queue>.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'en', 'Locked Ticket Pending Reminder Time Reached: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

the pending reminder time of the locked ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has been reached.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'en', 'Unlocked Ticket Pending Reminder Time Reached: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

the pending reminder time of the unlocked ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has been reached.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'en', 'Ticket Escalation! <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] is escalated!

Escalated at: <OFORK_TICKET_EscalationDestinationDate>
Escalated since: <OFORK_TICKET_EscalationDestinationIn>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'en', 'Ticket Escalation Warning! <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] will escalate!

Escalation at: <OFORK_TICKET_EscalationDestinationDate>
Escalation in: <OFORK_TICKET_EscalationDestinationIn>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>


-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'en', 'Ticket Service Update to <OFORK_TICKET_Service>: <OFORK_TICKET_Title>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

the service of ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has been updated to <OFORK_TICKET_Service>.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (14, 'text/html', 'en', 'Reminder: <OFORK_APPOINTMENT_TITLE>', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

appointment <OFORK_APPOINTMENT_TITLE> has reached its notification time.

Description: <OFORK_APPOINTMENT_DESCRIPTION>
Location: <OFORK_APPOINTMENT_LOCATION>
Calendar: <span style="color: <OFORK_CALENDAR_COLOR>;">■</span> <OFORK_CALENDAR_CALENDARNAME>
Start date: <OFORK_APPOINTMENT_STARTTIME>
End date: <OFORK_APPOINTMENT_ENDTIME>
All-day: <OFORK_APPOINTMENT_ALLDAY>
Repeat: <OFORK_APPOINTMENT_RECURRING>

<a href="<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=<OFORK_APPOINTMENT_APPOINTMENTID>" title="<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=<OFORK_APPOINTMENT_APPOINTMENTID>"><OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=<OFORK_APPOINTMENT_APPOINTMENTID></a>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'de', 'Ticket erstellt: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wurde in der Queue <OFORK_TICKET_Queue> erstellt.

<OFORK_CUSTOMER_REALNAME> schrieb:
<OFORK_CUSTOMER_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'de', 'Nachfrage zum freigegebenen Ticket: <OFORK_CUSTOMER_SUBJECT[24]>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

zum freigegebenen Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] gibt es eine Nachfrage.

<OFORK_CUSTOMER_REALNAME> schrieb:
<OFORK_CUSTOMER_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'de', 'Nachfrage zum gesperrten Ticket: <OFORK_CUSTOMER_SUBJECT[24]>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

zum gesperrten Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] gibt es eine Nachfrage.

<OFORK_CUSTOMER_REALNAME> schrieb:
<OFORK_CUSTOMER_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'de', 'Ticketsperre aufgehoben: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

die Sperrzeit des Tickets [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] ist abgelaufen. Es ist jetzt freigegeben.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'de', 'Änderung des Ticket-Besitzers auf <OFORK_OWNER_UserFullname>: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

der Besitzer des Tickets [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wurde von <OFORK_CURRENT_UserFullname> geändert auf <OFORK_TICKET_OWNER_UserFullname>.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'de', 'Änderung des Ticket-Verantwortlichen auf <OFORK_RESPONSIBLE_UserFullname>: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

der Verantwortliche für das Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wurde von <OFORK_CURRENT_UserFullname> geändert auf <OFORK_TICKET_RESPONSIBLE_UserFullname>.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'de', 'Ticket-Notiz: <OFORK_AGENT_SUBJECT[24]>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

<OFORK_CURRENT_UserFullname> schrieb:
<OFORK_AGENT_BODY[30]>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'de', 'Ticket-Queue geändert zu <OFORK_TICKET_Queue>: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wurde in die Queue <OFORK_TICKET_Queue> verschoben.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'de', 'Erinnerungszeit des gesperrten Tickets erreicht: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

die Erinnerungszeit für das gesperrte Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wurde erreicht.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'de', 'Erinnerungszeit des freigegebenen Tickets erreicht: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

die Erinnerungszeit für das freigegebene Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wurde erreicht.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'de', 'Ticket-Eskalation! <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] ist eskaliert!

Eskaliert am: <OFORK_TICKET_EscalationDestinationDate>
Eskaliert seit: <OFORK_TICKET_EscalationDestinationIn>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'de', 'Ticket-Eskalations-Warnung! <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wird bald eskalieren!

Eskalation um: <OFORK_TICKET_EscalationDestinationDate>
Eskalation in: <OFORK_TICKET_EscalationDestinationIn>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>


-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'de', 'Ticket-Service aktualisiert zu <OFORK_TICKET_Service>: <OFORK_TICKET_Title>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname> <OFORK_NOTIFICATION_RECIPIENT_UserLastname>,

der Service des Tickets [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] wurde geändert zu <OFORK_TICKET_Service>.

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (14, 'text/html', 'de', 'Erinnerung: <OFORK_APPOINTMENT_TITLE>', 'Hallo <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

Termin <OFORK_APPOINTMENT_TITLE> hat seine Benachrichtigungszeit erreicht.

Beschreibung: <OFORK_APPOINTMENT_DESCRIPTION>
Standort: <OFORK_APPOINTMENT_LOCATION>
Kalender: <span style="color: <OFORK_CALENDAR_COLOR>;">■</span> <OFORK_CALENDAR_CALENDARNAME>
Startzeitpunkt: <OFORK_APPOINTMENT_STARTTIME>
Endzeitpunkt: <OFORK_APPOINTMENT_ENDTIME>
Ganztägig: <OFORK_APPOINTMENT_ALLDAY>
Wiederholung: <OFORK_APPOINTMENT_RECURRING>

<a href="<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=<OFORK_APPOINTMENT_APPOINTMENTID>" title="<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=<OFORK_APPOINTMENT_APPOINTMENTID>"><OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=<OFORK_APPOINTMENT_APPOINTMENTID></a>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (15, 'text/plain', 'en', 'Email Delivery Failure', 'Hi <OFORK_NOTIFICATION_RECIPIENT_UserFirstname>,

Please note, that the delivery of an email article of [<OFORK_CONFIG_Ticket::Hook><OFORK_CONFIG_Ticket::HookDivider><OFORK_TICKET_TicketNumber>] has failed. Please check the email address of your recipient for mistakes and try again. You can manually resend the article from the ticket if required.

Error Message:
<OFORK_AGENT_TransmissionStatusMessage>

<OFORK_CONFIG_HttpType>://<OFORK_CONFIG_FQDN>/<OFORK_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OFORK_TICKET_TicketID>;ArticleID=<OFORK_AGENT_ArticleID>

-- <OFORK_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table dynamic_field
-- ----------------------------------------------------------
INSERT INTO dynamic_field (internal_field, name, label, field_order, field_type, object_type, config, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'ProcessManagementProcessID', 'Process', 1, 'ProcessID', 'Ticket', '---
DefaultValue: ''''
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table dynamic_field
-- ----------------------------------------------------------
INSERT INTO dynamic_field (internal_field, name, label, field_order, field_type, object_type, config, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'ProcessManagementActivityID', 'Activity', 1, 'ActivityID', 'Ticket', '---
DefaultValue: ''''
', 1, 1, current_timestamp, 1, current_timestamp);
SET DEFINE OFF;
SET SQLBLANKLINES ON;
