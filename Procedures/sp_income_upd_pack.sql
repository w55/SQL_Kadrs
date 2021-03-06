USE [Kadrs]
GO
/****** Object:  StoredProcedure [dbo].[sp_income_upd_pack]    Script Date: 27.02.2017 8:48:10 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


--
--		для внутренних и внешних по отношению к данной БД клиентов :
--
--		НачОК или офис-менеджер вносит изменения в пакетном режиме о приходе на работу сотрудника
--		при этом все старые записи за указанный период времени удаляются, и заносятся новые записи
--
ALTER                       PROCEDURE [dbo].[sp_income_upd_pack]
	@upd_whom int, @dep_id int, @dbuser_id int, @come_time varchar(20), @end_date varchar(20),
	@tab_id int, @amount int, @come_desc varchar(250), @out_db_id int = NULL
AS

IF @upd_whom < 1
begin
	RAISERROR(' Ошибочные входные параметры : Номер пользователя (%d) - должен быть больше нуля !!!', 16, 1, @upd_whom)
	return -1
end

IF @dep_id < 1
begin
	RAISERROR(' Ошибочные входные параметры : Номер отдела (%d) - должен быть больше нуля !!!', 16, 1, @dep_id)
	return -1
end

IF @dbuser_id < 1
begin
	RAISERROR(' Ошибочные входные параметры : Внутренний номер сотрудника (%d) - должен быть больше нуля !!!',
		16, 1, @dbuser_id)
	return -1
end

IF @come_time is null or @end_date is null
begin
	RAISERROR(' Ошибочные входные параметры: не заданы начальные дата и время либо конечная дата прихода на работу !!!', 16, 1)
	return -1
end

IF @amount is null
begin
	RAISERROR(' Ошибочные входные параметры : Не указано количество отработанного времени !!!', 16, 1)
	return -1
end

IF @amount < 0 or @amount > 12
begin
	RAISERROR(' Ошибочные входные параметры : количество отработанного времени (%d) - должен быть между 0 и 12 часами !!!',
		16, 1, @amount)
	return -1
end

--
--
IF not exists(select * from db_users where (dep_id = @dep_id and dbuser_id = @dbuser_id))
begin
	RAISERROR(' Ошибочные входные параметры: в указанном отделе указанный сотрудник больше не числится !!!', 16, 1)
	return -1
end

--	преобразуем дату
declare @dt1 as datetime, @dt2 as datetime

set @dt1 = convert(datetime,@come_time,104)
set @dt2 = convert(datetime,@end_date,104)


--
--	год, месяц, день для пакетного режима
--
declare @y1 as int, @y2 as int, @m1 as int, @m2 as int, @d1 as int, @d2 as int
declare @dt3 as datetime, @dt4 as datetime
declare @c_dt3 varchar(20), @c_dt4 varchar(20)


--		пакетный режим вставки записей

set @y1 = year(@dt1)
set @y2 = year(@dt2)

set @m1 = month(@dt1)
set @m2 = month(@dt2)

set @d1 = day(@dt1)
set @d2 = day(@dt2)

--	преобразуем дату
set @c_dt3 = ltrim(rtrim(str(@d1))) + '.' + ltrim(rtrim(str(@m1))) + '.' + ltrim(rtrim(str(@y1))) + ' 0:00:00'
set @dt3 = convert(datetime,@c_dt3,104)

set @c_dt4 = ltrim(rtrim(str(@d2))) + '.' + ltrim(rtrim(str(@m2))) + '.' + ltrim(rtrim(str(@y2))) + ' 23:59:59'
set @dt4 = convert(datetime,@c_dt4,104)

--
--
IF @dt3 > @dt4
begin
	RAISERROR(' Ошибочные входные параметры: начальная дата (%s) - больше конечной (%s) в пакетном режиме вставки !!!', 16, 1,
		@c_dt3, @c_dt4)
	return -1
end


begin tran	--	start transaction

IF exists(select * from income where ((come_time between @dt3 and @dt4) and dbuser_id = @dbuser_id))
begin
--	RAISERROR(' Ошибочные входные параметры: приход данного сотрудника между датами:  %s   и  %s  - уже отмечен !!!', 	16, 1,
--		@c_dt3, @c_dt4)
--	return -1

--
--	удаляем записи, если таковые есть за указанный период времени
--
	delete from income
		where (come_time between @dt3 and @dt4) and dbuser_id = @dbuser_id
	if @@ERROR <> 0
	begin
		rollback tran		--		rollback all transactions
		RAISERROR(' @@ERROR <> 0 - Ошибка при удалении записей за указанный период времени из таблицы income !!!',16, 1)
		return -1
	end
end


--
--	вставляем новые записи в таблицу income:
--
while @dt3 < @dt4
begin
	insert income(dep_id, dbuser_id, come_time, tab_id, amount, come_desc, out_db_id, upd_whom) 
		values(@dep_id, @dbuser_id, @dt1, @tab_id, @amount, @come_desc, @out_db_id, @upd_whom)
	if @@ROWCOUNT = 0
	begin
		rollback tran		--		rollback all transactions
		RAISERROR(' @@ROWCOUNT = 0 - Ошибка при вставке новой записи в таблицу income !!!',16, 1)
		return -1
	end

	set @dt1 = dateadd(day, 1, @dt1)
	set @dt3 = dateadd(day, 1, @dt3)
end

while @@TRANCOUNT > 0
	commit tran		--		commit all open transactions


