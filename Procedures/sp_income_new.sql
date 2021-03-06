USE [Kadrs]
GO
/****** Object:  StoredProcedure [dbo].[sp_income_new]    Script Date: 27.02.2017 8:51:05 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


--
--		для внутренних и внешних по отношению к данной БД клиентов :
--
--		офис-менеджер добавляет новый приход на работу 
--
ALTER                 PROCEDURE [dbo].[sp_income_new]
	@upd_whom int, @dep_id int, @dbuser_id int, @come_time varchar(20), @tab_id int, @amount int,
	@come_desc varchar(250), @out_db_id int = NULL
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

IF @come_time is null
begin
	RAISERROR(' Ошибочные входные параметры: не заданы дата и время прихода на работу !!!', 16, 1)
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


--	преобразуем дату
declare @dt1 as datetime
set @dt1 = convert(datetime,@come_time,104)


IF exists(select * from income where (year(come_time) = year(@dt1) and month(come_time) = month(@dt1) and 
	day(come_time) = day(@dt1) and dbuser_id = @dbuser_id))
begin
	RAISERROR(' Ошибочные входные параметры: приход данного сотрудника на указанную дату - уже отмечен !!!', 16, 1)
	return -1
end

--
--
IF not exists(select * from db_users where (dep_id = @dep_id and dbuser_id = @dbuser_id))
begin
	RAISERROR(' Ошибочные входные параметры: в указанном отделе указанный сотрудник больше не числится !!!', 16, 1)
	return -1
end

--
--	вставляем новую запись в таблицу income:
--
insert income(dep_id, dbuser_id, come_time, tab_id, amount, come_desc, out_db_id, upd_whom) 
	values(@dep_id, @dbuser_id, @dt1, @tab_id, @amount, @come_desc, @out_db_id, @upd_whom)
if @@ROWCOUNT = 0
begin
	RAISERROR(' @@ROWCOUNT = 0 - Ошибка при вставке новой записи в таблицу income !!!',16, 1)
	return -1
end



