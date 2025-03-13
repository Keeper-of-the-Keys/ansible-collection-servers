DROP PROCEDURE IF EXISTS `resolve_alias`;
DROP PROCEDURE IF EXISTS `dovecot_auth_domain_config`;
DROP PROCEDURE IF EXISTS `dovecot_auth_user_details`;
DROP PROCEDURE IF EXISTS `dovecot_auth_resolve_alias`;
DROP PROCEDURE IF EXISTS `dovecot_auth_primary_user`;
DROP PROCEDURE IF EXISTS `postfix_virtual_mailbox_domains`;
DROP PROCEDURE IF EXISTS `postfix_virtual_mailbox_maps`;
DROP PROCEDURE IF EXISTS `postfix_resolve_alias`;
DROP PROCEDURE IF EXISTS `postfix_sender_maps`;

DELIMITER //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `postfix_resolve_alias`(IN `inmail` VARCHAR(100), IN `recipient_delimiter` varchar(1)) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
set @last_at = - position('@' in reverse(inmail));
set @first_dash = position(recipient_delimiter in inmail);
set @length = length(inmail);

IF (@length - (@first_dash - @last_at)) > 0
THEN
	set @identifier = substr(inmail, @first_dash+1, @length - (@first_dash - @last_at));
	set @user = substring_index(inmail, recipient_delimiter, 1);
	set @domain = substring_index(inmail, '@', -1);

	SELECT `destination`
	FROM `virtual_aliases`
	WHERE
	(`requires_identifier` = 0 and `source` = inmail)
	or
	(@identifier != '' and @identifier REGEXP '[a-z,0-9]+' and `source` = concat(@user, '@', @domain));
ELSE
	SELECT `destination`
	FROM `virtual_aliases`
	WHERE
	(`source`=inmail and `requires_identifier` = 0);
END IF;

END //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `dovecot_auth_resolve_alias`(IN `inmail` VARCHAR(100), IN `recipient_delimiter` varchar(1)) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
set @last_at = - position('@' in reverse(inmail));
set @first_dash = position(recipient_delimiter in inmail);
set @length = length(inmail);

IF (@length - (@first_dash - @last_at)) > 0
THEN
	set @identifier = substr(inmail, @first_dash+1, @length - (@first_dash - @last_at));
	set @user = substring_index(inmail, recipient_delimiter, 1);
	set @domain = substring_index(inmail, '@', -1);

	with recursive `cte` as (
		select `tmp`.* from
		`virtual_aliases` as `tmp`
		where
		(`requires_identifier` = 0 and `tmp`.`source` = inmail)
		or
		(@identifier != '' and @identifier REGEXP '[a-z,0-9]+' and `tmp`.`source` = concat(@user, '@', @domain))
		union all
		select `tmp`.* from
		`cte` join
		`virtual_aliases` as `tmp` on
		`cte`.`destination` = `tmp`.`source`
		where `cte`.`source` != `cte`.`destination`
	) select `virtual_users`.`email`, `virtual_users`.`active`, `virtual_users`.`system_user` from `cte` inner join `virtual_users` on `virtual_users`.`email` = `cte`.`destination`;
ELSE
	with recursive `cte` as (
		select `tmp`.* from
		`virtual_aliases` as `tmp`
		where
		(`tmp`.`source` = inmail and `requires_identifier` = 0)
		union all
		select `tmp`.* from
		`cte` join
		`virtual_aliases` as `tmp` on
		`cte`.`destination` = `tmp`.`source`
		where `cte`.`source` != `cte`.`destination`
	) select `virtual_users`.`email`, `virtual_users`.`active`, `virtual_users`.`system_user` from `cte` inner join `virtual_users` on `virtual_users`.`email` = `cte`.`destination`;
END IF;

END //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `dovecot_auth_primary_user`(IN `inmail` VARCHAR(100), IN `recipient_delimiter` varchar(1), IN `allow_primary_password` BOOLEAN) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
set @last_at = - position('@' in reverse(inmail));
set @first_dash = position(recipient_delimiter in inmail);
set @length = length(inmail);

IF (@first_dash > 0) and (@length - (@first_dash - @last_at)) > 0
THEN
	set @identifier = substr(inmail, @first_dash+1, @length - (@first_dash - @last_at));
	set @user = substring_index(inmail, recipient_delimiter, 1);
	set @domain = substring_index(inmail, '@', -1);

	select
	`user_id` as `mail_user_id`,
	`email` as `email`,
	`active` as `active`,
	`system_user` as `system_user`,
	if(allow_primary_password, `primary_password`, '') as `mail_password_hash`,
	0 as `mail_password_id`
	from
	`virtual_users`
	where
	`email` = concat(@user, '@', @domain);
ELSE
	select
	`user_id` as `mail_user_id`,
	`email` as `email`,
	`active` as `active`,
	`system_user` as `system_user`,
	if(allow_primary_password, `primary_password`, '') as `mail_password_hash`,
	0 as `mail_password_id`
	from
	`virtual_users`
	where
	`email` = inmail;
END IF;

END //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `dovecot_auth_domain_config`(IN `indomain` VARCHAR(100)) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
	SELECT `backend_type`, `backend_uri`, `ldap_bind_dn`, `ldap_bind_password`, `ldap_base_dn`, `allow_primary_password`, `ldap_sync_cron` FROM `virtual_domains` WHERE `domain` = indomain;
END //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `dovecot_auth_user_details`(IN `inmail` VARCHAR(100)) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
	SELECT
	`virtual_users`.`user_id` AS `mail_user_id`,
	`virtual_users`.`email` AS `email`,
	`virtual_users`.`active` AS `active`,
	`virtual_users`.`system_user` AS `system_user`,
	`virtual_application_passwords`.`password_id` AS `mail_password_id`,
	`virtual_application_passwords`.`application_password` AS `mail_password_hash`
	FROM
	`virtual_application_passwords`
	INNER JOIN `virtual_users` ON `virtual_users`.`user_id` = `virtual_application_passwords`.`user_id`
	WHERE `virtual_application_passwords`.`application_username` = inmail;
END //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `postfix_virtual_mailbox_domains`(IN `indomain` VARCHAR(100)) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
	SELECT 1 FROM `virtual_domains` WHERE `domain` = indomain;
END //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `postfix_virtual_mailbox_maps`(IN `inmail` VARCHAR(100)) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
	SELECT 1 FROM `virtual_users` WHERE email= inmail;
END //

CREATE DEFINER=`mailserver_ro_procedures`@`localhost` PROCEDURE `postfix_sender_maps`(IN `inmail` VARCHAR(100)) NOT DETERMINISTIC READS SQL DATA SQL SECURITY DEFINER BEGIN
	SELECT `allowed_sender` FROM `virtual_senders` WHERE `address` = inmail;
END //

UPDATE `system_info` SET `value` = '20250312' WHERE `key` = 'schema_version';
