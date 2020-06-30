CREATE OR REPLACE FUNCTION "public"."RegisterKarjo"("karjo_info" text)
  RETURNS "pg_catalog"."json" AS $BODY$
	declare 
	fuid int; fbio text;fsat_rate int;fjobsno int; freg_time TIMESTAMP; fexpire_time TIMESTAMP;femp_type int;ftoken text; data_row text;data_json json; log_text text;fake_karjo_id int;
	err_context text;
	begin
	
	
	ftoken=karjo_info::json->>'token'::text;
	fuid = public.check_token(ftoken);
	
	if(fuid>0) then
			select karjo_id into fake_karjo_id from karjo where user_id=fuid limit 1;
			if(fake_karjo_id>0)then 
			data_json=json_strip_nulls(json_build_object('token',-1));
			return "OutputGenerator"('403', 'karjo already exists',data_json);
			end if;
			fbio=karjo_info::json->>'bio'::text;
			fsat_rate=(karjo_info::json->>'sat_rate')::int;
			fjobsno=(karjo_info::json->>'jobsno')::int;
			freg_time=CURRENT_TIMESTAMP;
			fexpire_time=CURRENT_TIMESTAMP+interval '7 days';
			femp_type=(karjo_info::json->>'emp_type')::int;
			
			insert into karjo (bio,sat_rate,jobsno,reg_time,expire_time,user_id,emp_type_id,karjo_status) 
			values(fbio,fsat_rate,fjobsno,freg_time,fexpire_time,fuid,femp_type,0);
			
	    data_json=json_build_object('sat_rate',fsat_rate,'reg_time',freg_time,'bio',fbio,'jobsno',fjobsno,'emp_type',femp_type,'karjo_status',0);
			
			select add_log(data_json::text, fuid) into log_text;
			
			return "OutputGenerator"('201','user created successfully',data_json);
			
			else
			data_json=json_strip_nulls(json_build_object('success','false'));
			return "OutputGenerator"('404','you need to sign in your token is invalid','{"log":"later"}');
			end if;
			
exception
when others then
 GET STACKED DIAGNOSTICS err_context = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error Name:%',SQLERRM;
        RAISE INFO 'Error State:%', SQLSTATE;
        RAISE INFO 'Error Context:%', err_context;

			return "OutputGenerator"('404','database error occured',SQLERRM);
	
	
	
	
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100




-------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."gather_certificates_with_national_id"("national_id" text)
  RETURNS "pg_catalog"."json" AS $BODY$
	declare
	d json;err_context text;
	BEGIN
	-- Routine body goes here...
	
	select array_to_json(array_agg(row_to_json(t))) into d from (select * from certificates t2 where national_code=national_id) t;
	
	
	RETURN "OutputGenerator"('200', 'successful', d);
	
	exception
when others then
 GET STACKED DIAGNOSTICS err_context = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error Name:%',SQLERRM;
        RAISE INFO 'Error State:%', SQLSTATE;
        RAISE INFO 'Error Context:%', err_context;

END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100

-----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."full_karjo_information"("karjo_id_input" int4, "token" text)
  RETURNS "pg_catalog"."json" AS $BODY$
	declare
	skills_json json;karjo_json json;skill_cert json; final_json json;ftoken text;fuid int;log_text text;err_context text;
	
	BEGIN
	-- Routine body goes here...
	
	fuid = public.check_token(token);
	
	if(fuid>0) then
		select row_to_json(t) into karjo_json from (select * from  karjo where karjo.karjo_id=karjo_id_input )t ;
		select array_to_json(array_agg(row_to_json(t))) into skills_json from (select * from skills where skills.karjo_id=karjo_id_input)t;
		select row_to_json(t) into skill_cert from (select * from  certificates where (skills_json->>'certificate_id')::int=certificates.certificate_id ) t ;

final_json=json_build_object('karjo',karjo_json,'skills',skills_json,'certificates',skill_cert);
	
	select add_log(final_json::text, fuid) into log_text;
	RETURN "OutputGenerator"('200', 'successful', final_json);
	
	else 
	return "OutputGenerator"('403', 'you need to login ', '{"token":-1}');
	end if;
	
		exception
when others then
 GET STACKED DIAGNOSTICS err_context = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error Name:%',SQLERRM;
        RAISE INFO 'Error State:%', SQLSTATE;
        RAISE INFO 'Error Context:%', err_context;

	
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."add_skill"("intext" text)
  RETURNS "pg_catalog"."json" AS $BODY$
	declare
	fcertificate_date DATE; fcertificate_title text; ffirst_name text;  flast_name text; fnational_code text;  fgender_id int; femail text;  fphone text; err_context text;log_text text;fuid text;ftoken text;
	BEGIN
	-- Routine body goes here...
	
	ftoken=intext::json->>'token'::text;
	fuid = public.check_token(ftoken);
	
	if(fuid>0) then
	fcertificate_date=(intext::json->>'certificate_date')::DATE;
	fcertificate_title=intext::json->>'certificate_title'::text;
	ffirst_name=intext::json->>'first_name'::text;
	flast_name=intext::json->>'last_name'::text;
	fnational_code=intext::json->>'national_code'::text;
	fgender_id=(intext::json->>'gender_id')::int;
	femail=intext::json->>'email'::text;
	fphone=intext::json->>'phone'::text;
	
	insert into certificates(certificate_date,certificate_title, first_name, last_name,national_code, gender_id,email,phone)
	values(fcertificate_date,fcertificate_title,ffirst_name ,flast_name,fnational_code,fgender_id,femail,fphone);
select add_log('inserted data to certificates', fuid) into log_text;

	RETURN "OutputGenerator"('201', 'successful', '');
	
	else 
	return "OutputGenerator"('403', 'you need to login', '{"token":-1}');
	end if;
	exception
when others then
 GET STACKED DIAGNOSTICS err_context = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error Name:%',SQLERRM;
        RAISE INFO 'Error State:%', SQLSTATE;
        RAISE INFO 'Error Context:%', err_context;

	
	
	
	
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100

-----------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."add_certificate"("intext" text)
  RETURNS "pg_catalog"."json" AS $BODY$
	declare
	fcertificate_date DATE; fcertificate_title text; ffirst_name text;  flast_name text; fnational_code text;  fgender_id int; femail text;  fphone text; err_context text; fuid int;ftoken text;log_text text;
	BEGIN
	-- Routine body goes here...
	--add log
	--add token check
	ftoken=karjo_info::json->>'token'::text;
	fuid = public.check_token(ftoken);
	
	if(fuid>0) then
	fcertificate_date=(intext::json->>'certificate_date')::DATE;
	fcertificate_title=intext::json->>'certificate_title'::text;
	ffirst_name=intext::json->>'first_name'::text;
	flast_name=intext::json->>'last_name'::text;
	fnational_code=intext::json->>'national_code'::text;
	fgender_id=(intext::json->>'gender_id')::int;
	femail=intext::json->>'email'::text;
	fphone=intext::json->>'phone'::text;
	
	insert into certificates(certificate_date,certificate_title, first_name, last_name,national_code, gender_id,email,phone)
	values(fcertificate_date,fcertificate_title,ffirst_name ,flast_name,fnational_code,fgender_id,femail,fphone);

	select add_log('inserted data to certificates', fuid) into log_text;
	RETURN "OutputGenerator"('201', 'successful', '') ;
	else 
	return "OutputGenerator"('403', 'you need to login', '{"token":-1}');
	
	end if;
	exception
when others then
 GET STACKED DIAGNOSTICS err_context = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error Name:%',SQLERRM;
        RAISE INFO 'Error State:%', SQLSTATE;
        RAISE INFO 'Error Context:%', err_context;

	
	
	
	
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100

-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."unregistered_karjo_list"()
  RETURNS "pg_catalog"."json" AS $BODY$
	declare 
	res text; d json;
	BEGIN
	
	-- add log 
	-- add token checking
	-- add exception handling
	select array_to_json(array_agg(row_to_json(t))) into d from (select * from karjo t2 where karjo_status=0) t;
	

	RETURN "OutputGenerator"('200', 'successfull', d) ;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
--------------------------------------------------------------------------------using below Defined functions-------------------

CREATE OR REPLACE FUNCTION "public"."check_token"(text)
  RETURNS "pg_catalog"."text" AS $BODY$
declare
	uid int;
begin
		select max(user_id) into uid from users where remember_token=$1 and
		token_expire>current_timestamp;
if uid is null then
raise notice 'there';
return -1;
else
update users set token_expire=Now()+1200 * '1 second'::interval
where user_id=uid;
return uid;
end if;
exception
WHEN others THEN
raise notice 'here';
return -1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."add_log"(text, int4)
  RETURNS "pg_catalog"."text" AS $BODY$
begin
	insert into users.dblog(cmdtext,loguser,logtime) values
	($1,$2,current_timestamp);
	return 'ok';
exception
WHEN others THEN
return SQLERRM;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
	
-----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."OutputGenerator"("status" text, "msg" text, "data" json)
  RETURNS "pg_catalog"."json" AS $BODY$BEGIN
	-- Routine body goes here...

	RETURN (json_build_object('status',status,'msg',msg,'data', data));
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
--------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.login(tusername text, tpassword text)
RETURNS json
LANGUAGE plpgsql AS $function$
declare
y varchar(500); cmdtext text; x varchar(50); uid int; d json;
begin
y='error of user name and password';
select max(password),max(user_id) into x, uid from users.user where username=$1 and status=1;
if(x=tpassword) then
	y=MD5(tusername||tpassword|| NOW());
	cmdtext='update users.user set remember_token=''' || y ||
	''',token_expire=Now()+1200 * ''1 second''::interval where user_id=' || uid;
	execute cmdtext;
	select Add_Log(cmdtext,uid) into cmdtext;
	d=json_strip_nulls(json_build_object('token',y));
	RETURN "OutputGenerator"('200','ok',d);
else
	d=json_strip_nulls(json_build_object('token','-1'));
	Return "OutputGenerator"('403', 'failed', d) ;
end if;
d=json_strip_nulls(json_build_object('token','-1'));
;)',dنشد یافت شده وارد پسورد یا کاربری نام','RETURN "OutputGenerator"('404
exception
when others then
d=json_strip_nulls(json_build_object('token','-1'));
RETURN "OutputGenerator"('404',sqlerrm,d);
END;
$function$;
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_token(text)
RETURNS text
LANGUAGE plpgsql
AS $function$
declare
uid int;
begin
select max(user_id) into uid from users.user where remember_token=$1 and
token_expire>current_timestamp;
if uid is null then
return -1;
else
update users.user set token_expire=Now()+1200 * '1 second'::interval
where user_id=uid;
return uid;
end if;
exception
WHEN others THEN
return -1;
END;
$function$;
--------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public."OutputGenerator"(status text, msg text, data
json)
RETURNS json
LANGUAGE plpgsql
AS $function$
begin
RETURN (json_build_object('status',status,'msg',msg,'data', data));
end;
$function$;
CREATE OR REPLACE FUNCTION public.add_log(text, integer)
RETURNS text
LANGUAGE plpgsql
AS $function$
begin
insert into users.dblog(cmdtext,loguser,logtime) values
($1,$2,current_timestamp);
return 'ok';
exception
WHEN others THEN
return SQLERRM;
END;
$function$;
-----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_province_townships(intext text)
RETURNS json
LANGUAGE plpgsql
AS $function$
declare
uid int; token text; d json; province_id text;
begin
token=intext::json->>'token'::text;
uid = public.check_token(token);
if(uid>0) then
province_id=intext::json->>'province_id'::text;
select array_to_json(array_agg(row_to_json(t))) into d from (select
* from ebus.townships t2 where provinceid =province_id::int) t;
RETURN "OutputGenerator"('200','Province TownShips',d);
end if ;
token='-1';
d=json_build_object('data',token);
RETURN "OutputGenerator"('404','unauthorized',d);
end;
$function$;
---------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.i_township(intext text)
RETURNS json
LANGUAGE plpgsql
AS $function$
declare
uid int; token text; d json; x text; province_id text; title text;
is_capital bool; is_active bool; lat text;lon text;
begin
token=intext::json->>'token'::text;
uid = public.check_token(token);
if(uid>0) then
province_id=intext::json->>'province_id'::int;
title=intext::json->>'title'::text;
is_capital=intext::json->>'is_capital'::bool;
is_active=intext::json->>'is_active'::bool;
lat=intext::json->>'lat'::int;
lon=intext::json->>'lon'::int;
INSERT INTO ebus.townships
(provinceid ,title ,iscapital ,isactive ,lat ,lon )
VALUES(province_id,title,is_capital,is_active,lat,lon);
x=(select max("id") from ebus.townships t );
d=json_build_object('id',x);
RETURN "OutputGenerator"('201','successful',d);
end if;
token='-1';
d=json_build_object('data',token);
RETURN "OutputGenerator"('404','unauthorized',d);
end;
$function$;
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.u_township(intext text)
RETURNS json
LANGUAGE plpgsql
AS $function$
declare
uid int; token text; d json; x text;township_id text; province_id text;
title text; is_capital bool; is_active bool; lat text;lon text;
begin
token=intext::json->>'token'::text;
uid = public.check_token(token);
if(uid>0) then
province_id=intext::json->>'province_id'::int;
title=intext::json->>'title'::text;
is_capital=intext::json->>'is_capital'::bool;
is_active=intext::json->>'is_active'::bool;
lat=intext::json->>'lat'::int;
lon=intext::json->>'lon'::int;
township_id=intext::json->>'id'::int;
UPDATE ebus.townships
SET provinceid =province_id,title =title,iscapital
=is_capital,isactive =is_active,lat =lat , lon =lon
WHERE id=province_id::int;
d=json_build_object('id',township_id);
d=json_build_object('id',x);
RETURN "OutputGenerator"('201','successful',d);
end if;
token='-1';
d=json_build_object('data',token);
RETURN "OutputGenerator"('404','unauthorized',d);
end;
$function$;
----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.d_province(intext text)
RETURNS json
LANGUAGE plpgsql
AS $function$
declare
uid int; token text; d json; province_id text ;
begin
token=intext::json->>'token'::text;
uid = public.check_token(token);
if(uid>0) then
province_id=intext::json->>'id'::text;
DELETE FROM ebus.provinces WHERE id=province_id::int;
d=json_build_object('id',province_id);
RETURN "OutputGenerator"('200','successfull delete',d);
end if ;
token='-1';
d=json_build_object('data',token);
RETURN "OutputGenerator"('404','unauthorized',d);
end;
$function$;
